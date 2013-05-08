#import "MVURLKit.h"
#import "MVFileUploadManager.h"
#import "MVFileUploadManager_Private.h"
#import "MVAssetsManager.h"
#import "MVMessageParser.h"

static MVURLKit *sharedInstance = nil;

@interface MVURLKit () <MVFileUploadManagerDelegate>

@property (strong, readwrite) MVFileUploadManager *fileUploadManager;
@property (strong, readwrite) MVAssetsManager *assetsManager;
@property (strong, readwrite) MVMessageParser *messageParser;

@end

@implementation MVURLKit

@synthesize uploadAuthorization     = uploadAuthorization_,
            fileUploadManager       = fileUploadManager_,
            assetsManager           = assetsManager_,
            messageParser           = messageParser_,
            delegate                = delegate_;

+ (MVURLKit*)sharedInstance
{
  if(!sharedInstance)
    sharedInstance = [[MVURLKit alloc] init];
  return sharedInstance;
}

- (id)init
{
  self = [super init];
  if(self)
  {
    uploadAuthorization_ = nil;
    assetsManager_ = [[MVAssetsManager alloc] init];
    fileUploadManager_ = [[MVFileUploadManager alloc] initWithAssetsManager:assetsManager_];
    fileUploadManager_.delegate = self;
    assetsManager_.fileUploadManager = fileUploadManager_;
    messageParser_ = [[MVMessageParser alloc] init];
    delegate_ = nil;
  }
  return self;
}

- (MVAsset*)uploadFileWithKey:(NSString*)key
                          data:(NSData*)data
{
  return [self.fileUploadManager uploadFileWithKey:key
                                              data:data];
}

- (MVAsset*)uploadAvatar:(NSData*)data
{
  return [self.fileUploadManager uploadAvatar:data];
}

- (BOOL)isAssetExistingForRemoteURL:(NSURL*)remoteURL
{
  return [self.assetsManager isAssetExistingForRemoteURL:remoteURL];
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                     download:(BOOL)download
{
  return [self.assetsManager assetForRemoteURL:remoteURL download:download];
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
{
  return [self.assetsManager assetForRemoteURL:remoteURL];
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize
{
  return [self.assetsManager assetForRemoteURL:remoteURL
                                   withMaxSize:maxSize];
}

- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize
                   ignoresGIFs:(BOOL)ignoresGIFs
{
  return [self.assetsManager assetForRemoteURL:remoteURL
                                   withMaxSize:maxSize
                                   ignoresGIFs:ignoresGIFs];
}

- (NSArray*)parseMessageForURLs:(NSString*)message
                  mentionRanges:(NSSet*)ranges
{
  return [self parseMessageForURLs:message
                     mentionRanges:ranges
        fetchServicesAutomatically:YES];
}

- (NSArray*)parseMessageForURLs:(NSString*)message
                  mentionRanges:(NSSet*)ranges
     fetchServicesAutomatically:(BOOL)fetchServicesAutomatically
{
  return [self.messageParser parseMessageForURLs:message
                                   mentionRanges:ranges
                      fetchServicesAutomatically:fetchServicesAutomatically];
}

#pragma mark -
#pragma mark Properties

- (void)setUploadAuthorization:(MVUploadAuthorization *)uploadAuthorization
{
  self.fileUploadManager.uploadAuthorization = uploadAuthorization;
  [self.fileUploadManager uploadPendingFiles];
}

- (MVUploadAuthorization*)uploadAuthorization
{
  return self.fileUploadManager.uploadAuthorization;
}

#pragma mark -
#pragma mark MVFileUploadManagerDelegate Methods

- (void)fileUploadManager:(MVFileUploadManager*)fileUploadManager
uploadAuthorizationDidExpired:(MVUploadAuthorization*)uploadAuthorization
{
  if([self.delegate respondsToSelector:@selector(urlKit:uploadAuthorizationDidExpired:)])
    [self.delegate urlKit:self uploadAuthorizationDidExpired:uploadAuthorization];
}

@end
