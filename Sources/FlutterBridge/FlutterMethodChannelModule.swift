import Foundation
import React
import Flutter
import FlutterPluginRegistrant

@objc(FlutterMethodChannelModule)
class FlutterMethodChannelModule: NSObject {
  
  private static var sharedEngine: FlutterEngine?
  
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
      
      let methodChannel = FlutterMethodChannel(
        name: "com.salespandadm.app/call",
        binaryMessenger: engine.binaryMessenger
      )
      
      // Construct deepLink using the provided parameters
      // Format: sp://home//{id}//{token}//debug//moamc
      let deepLink = "sp://\(pageKey)//\(id)//\(token)//debug//moamc"
      
      //          let sessionToken = "VFRKRk1VUXdWRWswTWpkRlJEWWtXVXc0VmxWTU9sUkpOREkzUlNvMUpGa2lNelV4TFQ0MFhUUTVWbEV0T2xSVlRETTJTU282Umlrbk95WlJRZ3BOTzBVcFJqZzFQVEU3SkZWS01qWlJMU3drTlV3ek5ra3FOU1UxSmpRM1JTNDZSanhSTXpaSk5TdzBTVFF5TjBVcU5TUkpKREpGTVNrK05qRWpDazAxTjBVdE9qVTFXalExTVNVc1ZGbEtPbE1sTFRVa1JWY3pOVEVoT3lSVlN6TTJVUzA2UkVsTE1rVXhLVDQwU1RRelJDa3FOU1JGV1RNMlNTRUtTVDQwV1Vrc0p6MHRORk1oV1ROSFJUVStORlVrTVRNcEtqVWtXU0l6TjBrNU95UlVVREV6SlMwd1ZUVlpNelpGTlN4VktTRXZNMVJnQ21BSw=="
      //          let deepLink = "sp://home//1//\(sessionToken)//debug//moamc"
      
      methodChannel.invokeMethod(deepLink, arguments: nil) { (result: Any?) in
        if let error = result as? FlutterError {
          print("FlutterMethodChannelModule: Method channel error: \(error.message ?? "Unknown error")")
          reject("METHOD_ERROR", error.message ?? "Unknown error", nil)
        } else {
          print("FlutterMethodChannelModule: Method channel called successfully with deepLink: \(deepLink)")
          resolve(["success": true, "deepLink": deepLink])
        }
      }
    }
  }
}

