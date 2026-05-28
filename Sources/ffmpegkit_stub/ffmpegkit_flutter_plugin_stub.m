#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

// Minimal arm64-simulator stub for FFmpegKitFlutterPlugin.
// Provides the class + required FlutterPlugin / FlutterStreamHandler methods
// so FlutterPluginRegistrant links on arm64 simulator without the real FFmpeg library.
@interface FFmpegKitFlutterPlugin : NSObject <FlutterPlugin, FlutterStreamHandler>
@end

@implementation FFmpegKitFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {}
- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events { return nil; }
- (FlutterError *)onCancelWithArguments:(id)arguments { return nil; }
@end
