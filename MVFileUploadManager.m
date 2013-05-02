#import "MVFileUploadManager.h"
#import "MVUploadAuthorization.h"
#import "MVFileUpload.h"
#import "MVAsset.h"
#import "MVAsset_Private.h"
#import "MVAssetsManager.h"
#import "MVAssetsManager_Private.h"
#import "MVFileUploadManager_Private.h"
#import "NSString+UUID.h"

@interface MVFileUploadManager () <MVFileUploadDelegate>

@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) NSMutableArray *fileUploads;
@property (strong, readwrite) NSMutableDictionary *fileUploadsByRemoteURL;
@property (strong, readwrite) NSMutableArray *pendingNonExpiredAuthFileUploads;
@property (strong, readwrite) NSMutableDictionary *assetsByFileUpload;

- (MVAsset*)uploadFileWithFullKey:(NSString *)fullKey data:(NSData *)data;

@end

@implementation MVFileUploadManager

@synthesize uploadAuthorization           = uploadAuthorization_,
            assetsManager                 = assetsManager_,
            operationQueue                = operationQueue_,
            fileUploads                   = fileUploads_,
            fileUploadsByRemoteURL        = fileUploadsByRemoteURL_,
            pendingNonExpiredAuthFileUploads  = pendingNonExpiredAuthFileUploads_,
            assetsByFileUpload            = assetsByFileUpload_,
            delegate                      = delegate_;

- (id)initWithAssetsManager:(MVAssetsManager*)assetsManager
{
  self = [super init];
  if(self)
  {
    assetsManager_ = assetsManager;
    operationQueue_ = [[NSOperationQueue alloc] init];
    fileUploads_ = [NSMutableArray array];
    fileUploadsByRemoteURL_ = [NSMutableDictionary dictionary];
    pendingNonExpiredAuthFileUploads_ = [NSMutableArray array];
    assetsByFileUpload_ = [NSMutableDictionary dictionary];
    delegate_ = nil;
  }
  return self;
}

- (MVAsset*)uploadFileWithKey:(NSString*)key
                          data:(NSData*)data
{
  NSString *uniqueID = [NSString mv_generateUUID];
  NSString *fullKey = [NSString stringWithFormat:@"%@%@/%@",
                       self.uploadAuthorization.startsWith,
                       uniqueID,
                       key];
  return [self uploadFileWithFullKey:fullKey data:data];
}

- (MVAsset*)uploadAvatar:(NSData*)data
{
  NSString *uniqueID = [NSString mv_generateUUID];
  NSString *fullKey = [NSString stringWithFormat:@"%@avatars/%@.png",
                       self.uploadAuthorization.startsWith,
                       uniqueID];
  return [self uploadFileWithFullKey:fullKey data:data];
}

#pragma mark -
#pragma mark MVFileUploadDelegate Methods

- (BOOL)fileUploadShouldStart:(MVFileUpload*)fileUpload
{
  if(fileUpload.uploadAuthorization != self.uploadAuthorization)
    fileUpload.uploadAuthorization = self.uploadAuthorization;
  if(fileUpload.uploadAuthorization.isExpired)
  {
    if(![self.pendingNonExpiredAuthFileUploads containsObject:fileUpload])
      [self.pendingNonExpiredAuthFileUploads addObject:fileUpload];
    if([self.delegate respondsToSelector:@selector(fileUploadManager:
                                                   uploadAuthorizationDidExpired:)])
      [self.delegate fileUploadManager:self
         uploadAuthorizationDidExpired:fileUpload.uploadAuthorization];
    return NO;
  }
  return YES;
}

- (void)fileUploadDidStart:(MVFileUpload *)fileUpload
{
}

- (void)fileUpload:(MVFileUpload *)fileUpload didProgress:(float)percent
{
}

- (void)fileUploadDidFinish:(MVFileUpload *)fileUpload
{
  [self.fileUploads removeObject:fileUpload];
  NSObject *key;
  for(key in self.fileUploadsByRemoteURL.allKeys)
  {
    if([self.fileUploadsByRemoteURL objectForKey:key] == fileUpload)
    {
      [self.fileUploadsByRemoteURL removeObjectForKey:key];
      break;
    }
  }
  [self.assetsByFileUpload removeObjectForKey:fileUpload.key];
}

- (void)fileUpload:(MVFileUpload *)fileUpload didFailWithError:(NSError *)error
{
}

#pragma mark -
#pragma mark Private Methods

- (MVAsset*)uploadFileWithFullKey:(NSString *)fullKey data:(NSData *)data
{
  NSString *remoteURLString = [NSString stringWithFormat:@"%@%@",
                               self.uploadAuthorization.uploadURL,
                               fullKey];
  remoteURLString =
  [remoteURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSURL *remoteURL = [NSURL URLWithString:remoteURLString];
  MVAsset *asset = [[MVAsset alloc] initWithRemoteURL:remoteURL
                                          assetsManager:self.assetsManager];
  NSURL *localURL = asset.localURL;

  NSString *destinationDirectory = [[localURL path] stringByDeletingLastPathComponent];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager createDirectoryAtPath:destinationDirectory
         withIntermediateDirectories:YES
                          attributes:nil
                               error:nil];
  [data writeToURL:localURL atomically:YES];

  MVFileUpload *fileUpload = [[MVFileUpload alloc] initWithKey:fullKey
                                                            data:data
                                                  operationQueue:self.operationQueue
                                             uploadAuthorization:self.uploadAuthorization];
  asset.fileUpload = fileUpload;
  fileUpload.delegate = self;
  [self.fileUploads addObject:fileUpload];
  [self.fileUploadsByRemoteURL setObject:fileUpload forKey:remoteURL];
  [self.assetsByFileUpload setObject:[NSArray arrayWithObject:asset] forKey:fileUpload.key];
  [fileUpload start];

  return asset;
}

- (MVFileUpload*)fileUploadWithRemoteURL:(NSURL*)remoteURL
{
  return [self.fileUploadsByRemoteURL objectForKey:remoteURL];
}

- (void)addAsset:(MVAsset*)asset usingFileUpload:(MVFileUpload*)fileUpload
{
  NSArray *array = [self.assetsByFileUpload objectForKey:fileUpload.key];
  if(!array)
    array = [NSArray array];
  array = [array arrayByAddingObject:asset];
  [self.assetsByFileUpload setObject:array forKey:fileUpload.key];
}

- (void)retryUpload:(MVAsset *)asset
{
  MVFileUpload *fileUpload = [self.fileUploadsByRemoteURL objectForKey:asset.remoteURL];
  if(!fileUpload)
    return;
  MVFileUpload *newFileUpload = [[MVFileUpload alloc] initWithKey:fileUpload.key
                                                               data:fileUpload.data
                                                     operationQueue:self.operationQueue
                                                uploadAuthorization:self.uploadAuthorization];
  NSArray *assets = [self.assetsByFileUpload objectForKey:fileUpload.key];
  if(assets)
  {
    MVAsset *assetUsingFileUpload;
    for(assetUsingFileUpload in assets)
    {
      assetUsingFileUpload.fileUpload = newFileUpload;
    }
  }
  newFileUpload.delegate = self;
  [self.fileUploads removeObject:fileUpload];
  [self.assetsByFileUpload removeObjectForKey:fileUpload.key];
  [self.fileUploads addObject:newFileUpload];
  [self.fileUploadsByRemoteURL setObject:newFileUpload forKey:asset.remoteURL];
  [self.assetsByFileUpload setObject:assets forKey:newFileUpload.key];
  [newFileUpload start];
}

- (void)uploadPendingFiles
{
  MVFileUpload *fileUpload;
  for(fileUpload in self.pendingNonExpiredAuthFileUploads)
  {
    [fileUpload start];
  }
  [self.pendingNonExpiredAuthFileUploads removeAllObjects];
}

@end
