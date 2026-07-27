#import <Foundation/Foundation.h>

/**
 * Simulator-only stub implementations for ffmpegkit native library symbols.
 *
 * The ffmpeg_kit_flutter_new plugin links against the real ffmpegkit C library,
 * which is only available for real iOS devices (no arm64-simulator slice exists
 * upstream). These stubs satisfy the linker AND the Objective-C runtime on
 * simulator by implementing every method FFmpegKitFlutterPlugin.m actually calls,
 * as safe no-ops, so the app doesn't crash with "unrecognized selector" when the
 * co-branding/FFmpeg flow runs on simulator.
 *
 * FFmpeg-related features will not function on simulator — they work on device,
 * where the real ffmpegkit.framework and the libav/libsw frameworks are vendored.
 */

long AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit = 10000;

typedef NS_ENUM(NSUInteger, Signal) {
    SignalSigint,
    SignalSigquit,
    SignalSigpipe,
    SignalSigterm,
    SignalSigxcpu
};

typedef NS_ENUM(NSUInteger, SessionState) {
    SessionStateCreated,
    SessionStateRunning,
    SessionStateFailed,
    SessionStateCompleted
};

typedef NS_ENUM(NSUInteger, LogRedirectionStrategy) {
    LogRedirectionStrategyAlwaysPrintLogs,
    LogRedirectionStrategyPrintLogsWhenNoCallbacksDefined,
    LogRedirectionStrategyPrintLogsWhenGlobalCallbackNotDefined,
    LogRedirectionStrategyPrintLogsWhenSessionCallbackNotDefined,
    LogRedirectionStrategyNeverPrintLogs
};

@class FFmpegSession, FFprobeSession, MediaInformationSession, MediaInformation, Log, Statistics;

typedef void (^FFmpegSessionCompleteCallback)(FFmpegSession *session);
typedef void (^FFprobeSessionCompleteCallback)(FFprobeSession *session);
typedef void (^MediaInformationSessionCompleteCallback)(MediaInformationSession *session);
typedef void (^LogCallback)(Log *log);
typedef void (^StatisticsCallback)(Statistics *statistics);

@interface ArchDetect : NSObject
+ (NSString *)getCpuArch;
+ (NSString *)getArch;
@end
@implementation ArchDetect
+ (NSString *)getCpuArch { return @"simulator-stub"; }
+ (NSString *)getArch { return @"simulator-stub"; }
@end

@interface FFmpegSession : NSObject @end
@implementation FFmpegSession @end

@interface FFprobeSession : NSObject @end
@implementation FFprobeSession @end

@interface MediaInformationSession : NSObject @end
@implementation MediaInformationSession @end

@interface MediaInformation : NSObject @end
@implementation MediaInformation @end

@interface Log : NSObject @end
@implementation Log @end

@interface Statistics : NSObject @end
@implementation Statistics @end

@interface FFmpegKit : NSObject
+ (FFmpegSession *)executeWithArguments:(NSArray *)arguments;
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback;
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback;
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (FFmpegSession *)execute:(NSString *)command;
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback;
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback;
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (void)cancel;
+ (void)cancel:(long)sessionId;
+ (NSArray *)listSessions;
@end
@implementation FFmpegKit
+ (FFmpegSession *)executeWithArguments:(NSArray *)arguments { return nil; }
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback { return nil; }
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback { return nil; }
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (FFmpegSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (FFmpegSession *)execute:(NSString *)command { return nil; }
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback { return nil; }
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback { return nil; }
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (FFmpegSession *)executeAsync:(NSString *)command withCompleteCallback:(FFmpegSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (void)cancel { }
+ (void)cancel:(long)sessionId { }
+ (NSArray *)listSessions { return @[]; }
@end

@interface FFprobeKit : NSObject
+ (FFprobeSession *)executeWithArguments:(NSArray *)arguments;
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback;
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback;
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (FFprobeSession *)execute:(NSString *)command;
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback;
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback;
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (MediaInformationSession *)getMediaInformation:(NSString *)path;
+ (MediaInformationSession *)getMediaInformation:(NSString *)path withTimeout:(int)waitTimeout;
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback;
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withTimeout:(int)waitTimeout;
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue;
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout;
+ (MediaInformationSession *)getMediaInformationFromCommand:(NSString *)command;
+ (MediaInformationSession *)getMediaInformationFromCommandAsync:(NSString *)command withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout;
+ (MediaInformationSession *)getMediaInformationFromCommandArgumentsAsync:(NSArray *)arguments withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout;
+ (NSArray *)listFFprobeSessions;
+ (NSArray *)listMediaInformationSessions;
@end
@implementation FFprobeKit
+ (FFprobeSession *)executeWithArguments:(NSArray *)arguments { return nil; }
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback { return nil; }
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback { return nil; }
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (FFprobeSession *)executeWithArgumentsAsync:(NSArray *)arguments withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (FFprobeSession *)execute:(NSString *)command { return nil; }
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback { return nil; }
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback { return nil; }
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (FFprobeSession *)executeAsync:(NSString *)command withCompleteCallback:(FFprobeSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (MediaInformationSession *)getMediaInformation:(NSString *)path { return nil; }
+ (MediaInformationSession *)getMediaInformation:(NSString *)path withTimeout:(int)waitTimeout { return nil; }
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback { return nil; }
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback withTimeout:(int)waitTimeout { return nil; }
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback onDispatchQueue:(dispatch_queue_t)queue { return nil; }
+ (MediaInformationSession *)getMediaInformationAsync:(NSString *)path withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout { return nil; }
+ (MediaInformationSession *)getMediaInformationFromCommand:(NSString *)command { return nil; }
+ (MediaInformationSession *)getMediaInformationFromCommandAsync:(NSString *)command withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout { return nil; }
+ (MediaInformationSession *)getMediaInformationFromCommandArgumentsAsync:(NSArray *)arguments withCompleteCallback:(MediaInformationSessionCompleteCallback)completeCallback withLogCallback:(LogCallback)logCallback onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout { return nil; }
+ (NSArray *)listFFprobeSessions { return @[]; }
+ (NSArray *)listMediaInformationSessions { return @[]; }
@end

@interface FFmpegKitConfig : NSObject
+ (void)enableRedirection;
+ (void)disableRedirection;
+ (int)setFontconfigConfigurationPath:(NSString *)path;
+ (void)setFontDirectory:(NSString *)fontDirectoryPath with:(NSDictionary *)fontNameMapping;
+ (void)setFontDirectoryList:(NSArray *)fontDirectoryList with:(NSDictionary *)fontNameMapping;
+ (NSString *)registerNewFFmpegPipe;
+ (void)closeFFmpegPipe:(NSString *)ffmpegPipePath;
+ (NSString *)getFFmpegVersion;
+ (NSString *)getVersion;
+ (int)isLTSBuild;
+ (NSString *)getBuildDate;
+ (int)setEnvironmentVariable:(NSString *)variableName value:(NSString *)variableValue;
+ (void)ignoreSignal:(Signal)signal;
+ (void)ffmpegExecute:(FFmpegSession *)ffmpegSession;
+ (void)ffprobeExecute:(FFprobeSession *)ffprobeSession;
+ (void)getMediaInformationExecute:(MediaInformationSession *)mediaInformationSession withTimeout:(int)waitTimeout;
+ (void)asyncFFmpegExecute:(FFmpegSession *)ffmpegSession;
+ (void)asyncFFmpegExecute:(FFmpegSession *)ffmpegSession onDispatchQueue:(dispatch_queue_t)queue;
+ (void)asyncFFprobeExecute:(FFprobeSession *)ffprobeSession;
+ (void)asyncFFprobeExecute:(FFprobeSession *)ffprobeSession onDispatchQueue:(dispatch_queue_t)queue;
+ (void)asyncGetMediaInformationExecute:(MediaInformationSession *)mediaInformationSession withTimeout:(int)waitTimeout;
+ (void)asyncGetMediaInformationExecute:(MediaInformationSession *)mediaInformationSession onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout;
+ (void)enableLogCallback:(LogCallback)logCallback;
+ (void)enableStatisticsCallback:(StatisticsCallback)statisticsCallback;
+ (void)enableFFmpegSessionCompleteCallback:(FFmpegSessionCompleteCallback)ffmpegSessionCompleteCallback;
+ (FFmpegSessionCompleteCallback)getFFmpegSessionCompleteCallback;
+ (void)enableFFprobeSessionCompleteCallback:(FFprobeSessionCompleteCallback)ffprobeSessionCompleteCallback;
+ (FFprobeSessionCompleteCallback)getFFprobeSessionCompleteCallback;
+ (void)enableMediaInformationSessionCompleteCallback:(MediaInformationSessionCompleteCallback)mediaInformationSessionCompleteCallback;
+ (MediaInformationSessionCompleteCallback)getMediaInformationSessionCompleteCallback;
+ (int)getLogLevel;
+ (void)setLogLevel:(int)level;
+ (NSString *)logLevelToString:(int)level;
+ (int)getSessionHistorySize;
+ (void)setSessionHistorySize:(int)sessionHistorySize;
+ (id)getSession:(long)sessionId;
+ (id)getLastSession;
+ (id)getLastCompletedSession;
+ (NSArray *)getSessions;
+ (void)clearSessions;
+ (NSArray *)getFFmpegSessions;
+ (NSArray *)getFFprobeSessions;
+ (NSArray *)getMediaInformationSessions;
+ (NSArray *)getSessionsByState:(SessionState)state;
+ (LogRedirectionStrategy)getLogRedirectionStrategy;
+ (void)setLogRedirectionStrategy:(LogRedirectionStrategy)logRedirectionStrategy;
+ (int)messagesInTransmit:(long)sessionId;
+ (NSString *)sessionStateToString:(SessionState)state;
+ (NSArray *)parseArguments:(NSString *)command;
+ (NSString *)argumentsToString:(NSArray *)arguments;
@end
@implementation FFmpegKitConfig
+ (void)enableRedirection { }
+ (void)disableRedirection { }
+ (int)setFontconfigConfigurationPath:(NSString *)path { return 0; }
+ (void)setFontDirectory:(NSString *)fontDirectoryPath with:(NSDictionary *)fontNameMapping { }
+ (void)setFontDirectoryList:(NSArray *)fontDirectoryList with:(NSDictionary *)fontNameMapping { }
+ (NSString *)registerNewFFmpegPipe { return nil; }
+ (void)closeFFmpegPipe:(NSString *)ffmpegPipePath { }
+ (NSString *)getFFmpegVersion { return @"simulator-stub"; }
+ (NSString *)getVersion { return @"simulator-stub"; }
+ (int)isLTSBuild { return 0; }
+ (NSString *)getBuildDate { return @"simulator-stub"; }
+ (int)setEnvironmentVariable:(NSString *)variableName value:(NSString *)variableValue { return 0; }
+ (void)ignoreSignal:(Signal)signal { }
+ (void)ffmpegExecute:(FFmpegSession *)ffmpegSession { }
+ (void)ffprobeExecute:(FFprobeSession *)ffprobeSession { }
+ (void)getMediaInformationExecute:(MediaInformationSession *)mediaInformationSession withTimeout:(int)waitTimeout { }
+ (void)asyncFFmpegExecute:(FFmpegSession *)ffmpegSession { }
+ (void)asyncFFmpegExecute:(FFmpegSession *)ffmpegSession onDispatchQueue:(dispatch_queue_t)queue { }
+ (void)asyncFFprobeExecute:(FFprobeSession *)ffprobeSession { }
+ (void)asyncFFprobeExecute:(FFprobeSession *)ffprobeSession onDispatchQueue:(dispatch_queue_t)queue { }
+ (void)asyncGetMediaInformationExecute:(MediaInformationSession *)mediaInformationSession withTimeout:(int)waitTimeout { }
+ (void)asyncGetMediaInformationExecute:(MediaInformationSession *)mediaInformationSession onDispatchQueue:(dispatch_queue_t)queue withTimeout:(int)waitTimeout { }
+ (void)enableLogCallback:(LogCallback)logCallback { }
+ (void)enableStatisticsCallback:(StatisticsCallback)statisticsCallback { }
+ (void)enableFFmpegSessionCompleteCallback:(FFmpegSessionCompleteCallback)ffmpegSessionCompleteCallback { }
+ (FFmpegSessionCompleteCallback)getFFmpegSessionCompleteCallback { return nil; }
+ (void)enableFFprobeSessionCompleteCallback:(FFprobeSessionCompleteCallback)ffprobeSessionCompleteCallback { }
+ (FFprobeSessionCompleteCallback)getFFprobeSessionCompleteCallback { return nil; }
+ (void)enableMediaInformationSessionCompleteCallback:(MediaInformationSessionCompleteCallback)mediaInformationSessionCompleteCallback { }
+ (MediaInformationSessionCompleteCallback)getMediaInformationSessionCompleteCallback { return nil; }
+ (int)getLogLevel { return 0; }
+ (void)setLogLevel:(int)level { }
+ (NSString *)logLevelToString:(int)level { return @""; }
+ (int)getSessionHistorySize { return 0; }
+ (void)setSessionHistorySize:(int)sessionHistorySize { }
+ (id)getSession:(long)sessionId { return nil; }
+ (id)getLastSession { return nil; }
+ (id)getLastCompletedSession { return nil; }
+ (NSArray *)getSessions { return @[]; }
+ (void)clearSessions { }
+ (NSArray *)getFFmpegSessions { return @[]; }
+ (NSArray *)getFFprobeSessions { return @[]; }
+ (NSArray *)getMediaInformationSessions { return @[]; }
+ (NSArray *)getSessionsByState:(SessionState)state { return @[]; }
+ (LogRedirectionStrategy)getLogRedirectionStrategy { return LogRedirectionStrategyNeverPrintLogs; }
+ (void)setLogRedirectionStrategy:(LogRedirectionStrategy)logRedirectionStrategy { }
+ (int)messagesInTransmit:(long)sessionId { return 0; }
+ (NSString *)sessionStateToString:(SessionState)state { return @""; }
+ (NSArray *)parseArguments:(NSString *)command { return @[]; }
+ (NSString *)argumentsToString:(NSArray *)arguments { return @""; }
@end

@interface MediaInformationJsonParser : NSObject
+ (MediaInformation *)from:(NSString *)ffprobeJsonOutput;
+ (MediaInformation *)fromWithError:(NSString *)ffprobeJsonOutput;
@end
@implementation MediaInformationJsonParser
+ (MediaInformation *)from:(NSString *)ffprobeJsonOutput { return nil; }
+ (MediaInformation *)fromWithError:(NSString *)ffprobeJsonOutput { return nil; }
@end

@interface Packages : NSObject
+ (NSString *)getPackageName;
+ (NSArray *)getExternalLibraries;
@end
@implementation Packages
+ (NSString *)getPackageName { return @"simulator-stub"; }
+ (NSArray *)getExternalLibraries { return @[]; }
@end
