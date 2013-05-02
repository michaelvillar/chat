#import "MVFileUploadManager.h"

@class MVFileUpload,
       MVAsset;

@interface MVFileUploadManager ()

- (MVFileUpload*)fileUploadWithRemoteURL:(NSURL*)remoteURL;
- (void)addAsset:(MVAsset*)asset usingFileUpload:(MVFileUpload*)fileUpload;
- (void)retryUpload:(MVAsset*)asset;
- (void)uploadPendingFiles;

@end
