import Foundation
import React
import Flutter
import FlutterPluginRegistrant

@objc(FlutterMethodChannelModule)
public class FlutterMethodChannelModule: NSObject {

  private static var sharedEngine: FlutterEngine?
  private static var sharedMethodChannel: FlutterMethodChannel?
  private static var dartReady = false
  private static var deeplinkDelivered = false
  // Stored here so flutterReady can send it immediately when Dart signals
  private static var pendingDeeplink: String? = nil

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  public static func getOrCreateEngine() -> FlutterEngine? {
    if let existingEngine = sharedEngine {
      return existingEngine
    }

    print("🚀 FlutterMethodChannelModule: Creating Flutter engine...")

    var appBundle: Bundle? = Bundle(identifier: "io.flutter.flutter.app")
    if appBundle == nil {
      if let frameworksPath = Bundle.main.privateFrameworksPath {
        let appFrameworkPath = (frameworksPath as NSString).appendingPathComponent("App.framework")
        appBundle = Bundle(path: appFrameworkPath)
      }
    }

    let flutterDartProject: FlutterDartProject
    if let bundle = appBundle {
      flutterDartProject = FlutterDartProject(precompiledDartBundle: bundle)
    } else {
      flutterDartProject = FlutterDartProject()
    }

    let engine = FlutterEngine(name: "flutter_engine_shared", project: flutterDartProject)
    engine.run()
    GeneratedPluginRegistrant.register(with: engine)

    let channel = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      NSLog("📲 [MC] Dart→iOS call: %@", call.method)
      if call.method == "closeSDK" {
        DispatchQueue.main.async {
          FlutterBridgeEventEmitter.shared?.sendCloseEvent()
        }
        result(nil)
      } else if call.method == "flutterReady" {
        // Dart handler is now registered — send pending deeplink immediately
        dartReady = true
        result(nil)
        DispatchQueue.main.async {
          FlutterBridgeEventEmitter.shared?.sendReadyEvent()
          if let deeplink = pendingDeeplink, let engine = sharedEngine, !deeplinkDelivered {
            pendingDeeplink = nil
            deeplinkDelivered = true
            NSLog("🟢 [MC] flutterReady — sending pending deeplink immediately: %@", deeplink)
            let ch = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
            ch.invokeMethod(deeplink, arguments: nil) { _ in }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    sharedMethodChannel = channel
    sharedEngine = engine
    print("✅ FlutterMethodChannelModule: Flutter engine created")
    return engine
  }

  @objc
  func initializeFlutterEngine(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      if FlutterMethodChannelModule.getOrCreateEngine() != nil {
        resolve(true)
      } else {
        reject("ENGINE_ERROR", "Failed to create Flutter engine", nil)
      }
    }
  }

  @objc
  func callFlutterMethodChannel(_ pageKey: String, id: String, token: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      guard let engine = FlutterMethodChannelModule.getOrCreateEngine() else {
        reject("NO_ENGINE", "Failed to create Flutter engine", nil)
        return
      }

      let deepLink = "sp://\(pageKey)//\(id)//\(token)//debug//moamc"
      resolve(["success": true, "deepLink": deepLink])

      // Reset state for this session
      FlutterMethodChannelModule.deeplinkDelivered = false
      FlutterMethodChannelModule.pendingDeeplink = deepLink

      if FlutterMethodChannelModule.dartReady {
        // Dart handler already registered — send once, use retry only as fallback.
        // Without this guard, scheduleDeepLinkRetry also fires immediately, sending
        // TWO deeplinks at once → Dart pushes the screen twice → nav stack gets dirty
        // → subsequent presses freeze or go to wrong screen.
        FlutterMethodChannelModule.pendingDeeplink = nil
        NSLog("🟢 [MC] dartReady — sending deeplink immediately: %@", deepLink)
        let ch = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
        ch.invokeMethod(deepLink, arguments: nil) { result in
          if result == nil {
            NSLog("✅ [MC] dartReady — deeplink delivered")
            FlutterMethodChannelModule.deeplinkDelivered = true
          } else {
            // Dart rejected — handler may have been re-registered; fall back to retry
            NSLog("⚠️ [MC] dartReady send rejected, starting retry loop")
            FlutterMethodChannelModule.scheduleDeepLinkRetry(deepLink: deepLink, engine: engine, attemptsLeft: 60)
          }
        }
      } else {
        // Cold start: Dart not ready yet — retry every 2s until flutterReady fires
        FlutterMethodChannelModule.scheduleDeepLinkRetry(deepLink: deepLink, engine: engine, attemptsLeft: 60)
      }
    }
  }

  private static func scheduleDeepLinkRetry(deepLink: String, engine: FlutterEngine, attemptsLeft: Int) {
    guard !deeplinkDelivered else { return }

    let ch = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
    NSLog("🔵 [MC] Sending deepLink (attempts left: %d): %@", attemptsLeft, deepLink)

    ch.invokeMethod(deepLink, arguments: nil) { result in
      if result == nil {
        NSLog("✅ [MC] Dart accepted deepLink via callback")
        deeplinkDelivered = true
        pendingDeeplink = nil
      }
    }

    guard attemptsLeft > 0 else {
      NSLog("❌ [MC] Max retries reached, giving up")
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      guard !deeplinkDelivered else {
        NSLog("✅ [MC] Deeplink already delivered, stopping retries")
        return
      }
      scheduleDeepLinkRetry(deepLink: deepLink, engine: engine, attemptsLeft: attemptsLeft - 1)
    }
  }
}
