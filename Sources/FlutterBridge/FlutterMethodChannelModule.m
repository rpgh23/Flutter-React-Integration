#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(FlutterMethodChannelModule, NSObject)

RCT_EXTERN_METHOD(initializeFlutterEngine:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(callFlutterMethodChannel:(NSString *)pageKey
                  id:(NSString *)id
                  token:(NSString *)token
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end

