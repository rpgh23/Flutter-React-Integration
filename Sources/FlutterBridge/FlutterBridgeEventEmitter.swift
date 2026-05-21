import Foundation
import React

@objc(FlutterBridgeEventEmitter)
class FlutterBridgeEventEmitter: RCTEventEmitter {
  static var shared: FlutterBridgeEventEmitter?

  override init() {
    super.init()
    FlutterBridgeEventEmitter.shared = self
  }

  @objc override static func requiresMainQueueSetup() -> Bool { return true }

  override func supportedEvents() -> [String]! {
    return ["onFlutterSDKClose"]
  }

  func sendCloseEvent() {
    sendEvent(withName: "onFlutterSDKClose", body: nil)
  }
}
