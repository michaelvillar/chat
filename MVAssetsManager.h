#import <Foundation/Foundation.h>

@class MVAsset,
       MVFileUploadManager;

@interface MVAssetsManager : NSObject

@property (strong, readwrite) MVFileUploadManager *fileUploadManager;

- (BOOL)isAssetExistingForRemoteURL:(NSURL*)remoteURL;
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL;
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize;
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize
                   ignoresGIFs:(BOOL)ignoresGIFs;

@end
