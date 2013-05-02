#import <Foundation/Foundation.h>

@class MVAssetsManager;

@interface MVAsset : NSObject

@property (strong, readonly) NSURL *localURL;
@property (strong, readwrite) NSURL *remoteURL;
@property (readonly, getter = isExisting) BOOL existing;
@property (readonly) float downloadPercentage;
@property (readonly) float uploadPercentage;
@property (readonly) BOOL uploadFinished;
@property (readonly, nonatomic) BOOL error;
@property (strong, readwrite, nonatomic) MVAsset *originalAsset;

- (id)initWithRemoteURL:(NSURL*)remoteURL
          assetsManager:(MVAssetsManager*)assetsManager;
- (id)initWithRemoteURL:(NSURL*)remoteURL
          assetsManager:(MVAssetsManager*)assetsManager
            withMaxSize:(CGSize)maxSize;
- (void)retryDownload;
- (void)retryUpload;

@end
