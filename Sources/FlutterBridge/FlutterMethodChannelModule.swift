import Foundation
import React
import Flutter
import FlutterPluginRegistrant

@objc(FlutterMethodChannelModule)
class FlutterMethodChannelModule: NSObject {

  private static var sharedEngine: FlutterEngine?
  private static var sharedMethodChannel: FlutterMethodChannel?
  // Set to true once Dart's initState registers its handler and fires 'flutterReady'
  private static var dartReady = false
  // Deeplink stored here when callFlutterMethodChannel is called before dartReady
  private static var pendingDeeplink: String? = nil
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  // Get or create the Flutter engine
  static func getOrCreateEngine() -> FlutterEngine? {
    if let existingEngine = sharedEngine {
      return existingEngine
    }
    
    print("🚀 FlutterMethodChannelModule: Creating Flutter engine...")
    
    // Find the App.framework bundle
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
    
    let engineName = "flutter_engine_shared"
    let engine = FlutterEngine(name: engineName, project: flutterDartProject)
    engine.run()
    GeneratedPluginRegistrant.register(with: engine)

    // Keep a persistent channel to receive calls FROM Dart (e.g. closeSDK)
    let channel = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      NSLog("📲 [MC] Dart→iOS call: %@", call.method)
      if call.method == "closeSDK" {
        DispatchQueue.main.async {
          FlutterBridgeEventEmitter.shared?.sendCloseEvent()
        }
        result(nil)
      } else if call.method == "flutterReady" {
        dartReady = true
        DispatchQueue.main.async {
          FlutterBridgeEventEmitter.shared?.sendReadyEvent()
          // If a deeplink was stored while Dart was still starting, send it now
          if let deeplink = pendingDeeplink, let engine = sharedEngine {
            pendingDeeplink = nil
            NSLog("🟢 [MC] Dart ready — sending stored deeplink: %@", deeplink)
            let ch = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
            ch.invokeMethod(deeplink, arguments: nil) { _ in }
          }
        }
        result(nil)
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

      if FlutterMethodChannelModule.dartReady {
        // Dart handler already registered — send immediately
        NSLog("🔵 [MC] Dart ready — sending deepLink now: %@", deepLink)
        let ch = FlutterMethodChannel(name: "com.salespandadm.app/call", binaryMessenger: engine.binaryMessenger)
        ch.invokeMethod(deepLink, arguments: nil) { _ in }
        resolve(["success": true, "deepLink": deepLink])
      } else {
        // Dart not ready yet — store deeplink; sent automatically when flutterReady fires
        NSLog("🟡 [MC] Dart not ready — storing deepLink for later: %@", deepLink)
        FlutterMethodChannelModule.pendingDeeplink = deepLink
        resolve(["success": true, "deepLink": deepLink])
      }
    }
  }
}

