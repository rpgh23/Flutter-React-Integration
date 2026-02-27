#import <React/RCTViewManager.h>
#import <React/RCTComponent.h>

/**
 * Objective‑C externs to expose the Swift view manager to React Native.
 *
 * This registers a native component called `RNFlutterView`, which matches
 * the string used in `requireNativeComponent('RNFlutterView')` on JS side.
 */
@interface RCT_EXTERN_MODULE(RNFlutterView, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(route, NSString)
RCT_EXPORT_VIEW_PROPERTY(initialData, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(onMessage, RCTBubblingEventBlock)

@end

