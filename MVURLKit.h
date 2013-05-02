#import <Foundation/Foundation.h>

// Import public headers
#import "MVUploadAuthorization.h"
#import "MVAsset.h"
#import "MVMessage.h"
#import "MVService.h"
#import "MVKickoffFileService.h"
#import "MVKickoffTaskService.h"
#import "MVDribbbleShotService.h"
#import "MVTwitterTweetService.h"
#import "MVYoutubeVideoService.h"
#import "MVCloudAppLinkService.h"
#import "MVVimeoVideoService.h"
#import "MVFlickrPhotoService.h"
#import "MVImageService.h"
#import "MVDroplrLinkService.h"
#import "NSString+EscapeForRegexPattern.h"

#define kMVMentionAttributeName @"kMVMentionAttributeName"

@class MVURLKit,
       MVUploadAuthorization;

@protocol MVURLKitDelegate

- (void)urlKit:(MVURLKit*)urlKit
uploadAuthorizationDidExpired:(MVUploadAuthorization*)uploadAuthorization;

@end

@interface MVURLKit : NSObject

@property (strong, readwrite) MVUploadAuthorization *uploadAuthorization;
@property (weak, readwrite) NSObject <MVURLKitDelegate> *delegate;

+ (MVURLKit*)sharedInstance;
- (MVAsset*)uploadFileWithKey:(NSString*)key
                          data:(NSData*)data;
- (MVAsset*)uploadAvatar:(NSData*)data;
- (BOOL)isAssetExistingForRemoteURL:(NSURL*)remoteURL;
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL;
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize;
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
                   withMaxSize:(CGSize)maxSize
                   ignoresGIFs:(BOOL)ignoresGIFs;
- (NSArray*)parseMessageForURLs:(NSString*)message
                  mentionRanges:(NSSet*)ranges;
- (NSArray*)parseMessageForURLs:(NSString*)message
                  mentionRanges:(NSSet*)ranges
     fetchServicesAutomatically:(BOOL)fetchServicesAutomatically;

@end
