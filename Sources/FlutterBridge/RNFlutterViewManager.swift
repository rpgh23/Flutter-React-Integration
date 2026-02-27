import Foundation
import UIKit
import React
import Flutter
import ObjectiveC

/**
 * Custom view class that holds the Flutter view and handles props
 */
@objc(RNFlutterContainerView)
class RNFlutterContainerView: UIView {
  @objc var route: NSString?
  @objc var initialData: NSDictionary?
  @objc var onMessage: RCTBubblingEventBlock?
  
  private var flutterVC: FlutterViewController?
  private var flutterEngine: FlutterEngine?
  
  override func didSetProps(_ changedProps: [String]!) {
    // Handle prop changes here if needed
    if changedProps.contains("route") || changedProps.contains("initialData") {
      // You can update Flutter with new route/data here
      print("RNFlutterContainerView: Props changed - route: \(route ?? "nil"), initialData: \(initialData ?? [:])")
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    print("📐 RNFlutterContainerView: layoutSubviews - bounds: \(bounds)")
    flutterVC?.view.frame = bounds
    flutterVC?.view.setNeedsLayout()
  }
  
  func setupFlutterView() {
    guard flutterVC == nil else { 
      print("⚠️ RNFlutterViewManager: Flutter view already set up")
      return 
    }
    
    print("🚀 RNFlutterViewManager: Setting up Flutter view using shared engine...")
    
    // Use the shared engine from FlutterMethodChannelModule
    guard let engine = FlutterMethodChannelModule.getOrCreateEngine() else {
      print("❌ RNFlutterViewManager: Failed to get shared Flutter engine")
      return
    }
    
    print("✅ RNFlutterViewManager: Got shared Flutter engine: \(engine)")
    
    // Small delay to ensure engine is fully ready after method channel calls
    // This prevents race conditions and freezing issues
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      guard let self = self, self.flutterVC == nil else { return }
      
      // Create FlutterViewController with the shared engine
      let vc = FlutterViewController(
        engine: engine,
        nibName: nil,
        bundle: nil
      )
      
      // Add Flutter view to container
      vc.view.frame = self.bounds
      vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      vc.view.backgroundColor = .white
      vc.view.isHidden = false
      self.addSubview(vc.view)
      print("📐 RNFlutterContainerView: Added Flutter view with frame: \(self.bounds)")
      
      // Keep references
      self.flutterVC = vc
      self.flutterEngine = engine
      
      print("✅ RNFlutterViewManager: Flutter view created using shared engine")
    }
  }
  
//  @objc
//  func callFlutterMethodChannel() {
//    guard let engine = self.flutterEngine else {
//      print("RNFlutterViewManager: Flutter engine not found")
//      return
//    }
//    let methodChannel = FlutterMethodChannel(
//      name: "com.salespandadm.app/call",
//      binaryMessenger: engine.binaryMessenger
//    )
//    
//    let sessionToken = "VFRKRk1VUXdWRWswTWpkRlJEWWtXVXc0VmxWTU9sUkpOREkzUlNvMUpGa2lNelV4TFQ0MFhUUTVWbEV0T2xSVlRETTJTU282Umlrbk95WlJRZ3BOTzBVcFJqZzFQVEU3SkZWS01qWlJMU3drTlV3ek5ra3FOU1UxSmpRM1JTNDZSanhSTXpaSk5TdzBTVFF5TjBVcU5TUkpKREpGTVNrK05qRWpDazAxTjBVdE9qVTFXalExTVNVc1ZGbEtPbE1sTFRVa1JWY3pOVEVoT3lSVlN6TTJVUzA2UkVsTE1rVXhLVDQwU1RRelJDa3FOU1JGV1RNMlNTRUtTVDQwV1Vrc0p6MHRORk1oV1ROSFJUVStORlVrTVRNcEtqVWtXU0l6TjBrNU95UlVVREV6SlMwd1ZUVlpNelpGTlN4VktTRXZNMVJnQ21BSw=="
//    
//    let deepLink = "sp://home//0//\(sessionToken)//debug//moamc"
//    
//    methodChannel.invokeMethod(deepLink, arguments: nil) {[weak self] (result: Any?) in
//      if let error = result as? FlutterError {
//        print("RNFlutterViewManager: Method channel error: \(error.message ?? "Unknown error")")
//      } else {
//        print("RNFlutterViewManager: Method channel called successfully with deepLink: \(deepLink)")
//      }
//    }
//  }
}

/**
 * Native view manager for the embedded Flutter view.
 *
 * JS side uses:
 *   requireNativeComponent('RNFlutterView')
 *
 * So we expose a view manager whose Objective‑C name is `RNFlutterView`.
 */
@objc(RNFlutterView)
class RNFlutterViewManager: RCTViewManager {

  override static func requiresMainQueueSetup() -> Bool {
    // We touch UIKit, so we require main queue setup.
    return true
  }

  override func view() -> UIView! {
    let containerView = RNFlutterContainerView()
    containerView.backgroundColor = .white
    containerView.clipsToBounds = true
    
    print("🚀 RNFlutterViewManager: Creating container view")
    
    // Setup Flutter view after the view is created and laid out
    // Use a small delay to ensure the view hierarchy is ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      print("🚀 RNFlutterViewManager: Setting up Flutter view, container bounds: \(containerView.bounds)")
      containerView.setupFlutterView()
    }
    
    return containerView
  }
}
