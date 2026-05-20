#import <Foundation/Foundation.h>

/**
 * Simulator-only stub implementations for ffmpegkit native library symbols.
 *
 * The ffmpeg_kit_flutter_new_min plugin links against the ffmpegkit C library.
 * That library is only available for real iOS devices. These empty stubs
 * satisfy the linker on simulator so the app builds and launches.
 *
 * FFmpeg-related features will not function on simulator — they work on device.
 */

long AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit = 10000;

@interface ArchDetect : NSObject @end
@implementation ArchDetect @end

@interface FFmpegKit : NSObject @end
@implementation FFmpegKit @end

@interface FFmpegKitConfig : NSObject @end
@implementation FFmpegKitConfig @end

@interface FFmpegSession : NSObject @end
@implementation FFmpegSession @end

@interface FFprobeKit : NSObject @end
@implementation FFprobeKit @end

@interface FFprobeSession : NSObject @end
@implementation FFprobeSession @end

@interface MediaInformationJsonParser : NSObject @end
@implementation MediaInformationJsonParser @end

@interface MediaInformationSession : NSObject @end
@implementation MediaInformationSession @end

@interface Packages : NSObject @end
@implementation Packages @end
