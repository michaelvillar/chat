#import "MVAssetsManager.h"
#import "NSString+Digest.h"
#import "MVFileDownload.h"
#import "MVAsset.h"
#import "MVAsset_Private.h"
#import "MVAssetsManager_Private.h"
#import "MVFileUploadManager_Private.h"
#import "NSString+QueryParsing.h"

@interface MVAssetsManager () <MVFileDownloadDelegate>

@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) NSMutableArray *fileDownloads;
@property (nonatomic, strong) NSCache *localURLForRemoteURL;

@end

@implementation MVAssetsManager

@synthesize operationQueue        = operationQueue_,
            fileDownloads         = fileDownloads_,
            fileUploadManager     = fileUploadManager_,
            localURLForRemoteURL  = localURLForRemoteURL_;

- (id)init
{
  self = [super init];
  if(self)
  {
    operationQueue_ = [[NSOperationQueue alloc] init];
    fileDownloads_ = [NSMutableArray array];
    fileUploadManager_ = nil;
    localURLForRemoteURL_ = [[NSCache alloc] init];
  }
  return self;
}

- (BOOL)isAssetExistingForRemoteURL:(NSURL*)remoteURL
{
  MVAsset *asset = [[MVAsset alloc] initWithRemoteURL:remoteURL
                                          assetsManager:self];
  return asset.isExisting;
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                     download:(BOOL)download
{
  MVAsset *asset = [[MVAsset alloc] initWithRemoteURL:remoteURL
                                        assetsManager:self];
  if(download)
  {
    NSURL *localURL = asset.localURL;
    if(!asset.isExisting)
    {
      BOOL existsFileDownload = NO;
      MVFileDownload *fileDownload;
      // search for an existing fileDownload
      for(fileDownload in self.fileDownloads)
      {
        if([fileDownload.destinationURL isEqual:localURL])
        {
          existsFileDownload = YES;
          break;
        }
      }
      
      if(!existsFileDownload)
      {
        fileDownload = [[MVFileDownload alloc] initWithSourceURL:remoteURL
                                                  destinationURL:localURL
                                                  operationQueue:self.operationQueue];
        fileDownload.delegate = self;
        [self.fileDownloads addObject:fileDownload];
        [fileDownload start];
      }
      
      asset.fileDownload = fileDownload;
    }
    else
    {
      MVFileUpload *fileUpload = [self.fileUploadManager fileUploadWithRemoteURL:remoteURL];
      if(fileUpload)
      {
        asset.fileUpload = fileUpload;
        [self.fileUploadManager addAsset:asset usingFileUpload:fileUpload];
      }
    }
  }
  return asset;
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
{
  return [self assetForRemoteURL:remoteURL download:YES];
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize
{
  return [self assetForRemoteURL:remoteURL withMaxSize:maxSize ignoresGIFs:NO];
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize
                   ignoresGIFs:(BOOL)ignoresGIFs
{
  MVAsset *originalAsset = [self assetForRemoteURL:remoteURL];
  CFStringRef fileExtension = (__bridge CFStringRef)(remoteURL.pathExtension);
  CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                              fileExtension,
                                                              NULL);
  if(!(UTTypeConformsTo(fileUTI, kUTTypeJPEG) ||
       UTTypeConformsTo(fileUTI, kUTTypeJPEG2000) ||
       UTTypeConformsTo(fileUTI, kUTTypeTIFF) ||
       UTTypeConformsTo(fileUTI, kUTTypePICT) ||
       UTTypeConformsTo(fileUTI, kUTTypeGIF) ||
       UTTypeConformsTo(fileUTI, kUTTypePNG) ||
       UTTypeConformsTo(fileUTI, kUTTypeAppleICNS) ||
       UTTypeConformsTo(fileUTI, kUTTypeBMP) ||
       UTTypeConformsTo(fileUTI, kUTTypeICO)) ||
     (ignoresGIFs && UTTypeConformsTo(fileUTI, kUTTypeGIF)))
    return originalAsset;

  MVAsset *asset = [[MVAsset alloc] initWithRemoteURL:remoteURL
                                          assetsManager:self
                                            withMaxSize:(CGSize)maxSize];
  asset.originalAsset = originalAsset;
  if(originalAsset.fileDownload)
    asset.fileDownload = originalAsset.fileDownload;
  MVFileUpload *fileUpload = [self.fileUploadManager fileUploadWithRemoteURL:remoteURL];
  if(fileUpload)
  {
    asset.fileUpload = fileUpload;
    [self.fileUploadManager addAsset:asset usingFileUpload:fileUpload];
  }
  if(originalAsset.isExisting)
     [asset generateResizedFile];
  return asset;
}

#pragma mark -
#pragma mark Private Methods

- (NSURL*)resolveLocalURLForRemoteURL:(NSURL*)url
{
  return [self resolveLocalURLForRemoteURL:url andToken:nil];
}

- (NSURL*)resolveLocalURLForRemoteURL:(NSURL*)url
                             andToken:(NSString*)token
{
  if (!url) return nil;

  NSMutableString *toDigest = [NSMutableString stringWithString:[url absoluteString]];
  if(token)
    [toDigest appendString:token];

  // first try to get the localURL from the cache, cause computing its value is expansive
  NSURL *localURL = [self.localURLForRemoteURL objectForKey:toDigest];

  if (localURL!=nil) return localURL;

  // the localURL was not found in the cache, compute it
  NSString *urlDigest = [toDigest mv_digest];
  NSString *filePath = [[self cachePath] stringByAppendingPathComponent:urlDigest];

  NSString *fileName = [url lastPathComponent];
  if(url.fragment)
  {
    NSDictionary *fragments = url.fragment.dictionaryFromQueryComponents;
    if([fragments valueForKey:@"chat_filename"])
    {
      fileName = [[fragments valueForKey:@"chat_filename"] objectAtIndex:0];
    }
  }
  filePath = [filePath stringByAppendingPathComponent:fileName];

  localURL = [NSURL fileURLWithPath:filePath];
  [self.localURLForRemoteURL setObject:localURL forKey:toDigest];

  return localURL;
}

- (NSString*)cachePath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *filePath = [paths objectAtIndex:0];
  filePath = [filePath stringByAppendingPathComponent:kMVAssetsCachePath];

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:filePath]) return filePath;

  [fileManager createDirectoryAtPath:filePath
         withIntermediateDirectories:YES
                          attributes:nil
                               error:nil];
  return filePath;
}

- (void)retryUpload:(MVAsset*)asset
{
  [self.fileUploadManager retryUpload:asset];
}

#pragma mark -
#pragma mark MVFileDownloadDelegate Methods

- (void)fileDownloadDidFinish:(MVFileDownload *)fileDownload
{
  [self.fileDownloads removeObject:fileDownload];
}

- (void)fileDownload:(MVFileDownload *)fileDownload didFailWithError:(NSError *)error
{
  [self.fileDownloads removeObject:fileDownload];
}

@end
