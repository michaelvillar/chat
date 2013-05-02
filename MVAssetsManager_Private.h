#import "MVAssetsManager.h"

@class MVAsset;

@interface MVAssetsManager ()

@property (strong, readonly) NSString *cachePath;
- (NSURL*)resolveLocalURLForRemoteURL:(NSURL*)url;
- (NSURL*)resolveLocalURLForRemoteURL:(NSURL*)url
                             andToken:(NSString*)token;
- (void)retryUpload:(MVAsset*)asset;

@end
