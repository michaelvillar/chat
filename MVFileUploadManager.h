#import <Foundation/Foundation.h>

@class MVUploadAuthorization,
       MVAssetsManager,
       MVAsset,
       MVFileUploadManager;

@protocol MVFileUploadManagerDelegate

- (void)fileUploadManager:(MVFileUploadManager*)fileUploadManager
uploadAuthorizationDidExpired:(MVUploadAuthorization*)uploadAuthorization;

@end

@interface MVFileUploadManager : NSObject

@property (strong, readwrite) MVUploadAuthorization *uploadAuthorization;
@property (strong, readwrite) MVAssetsManager *assetsManager;
@property (weak, readwrite) NSObject<MVFileUploadManagerDelegate> *delegate;

- (id)initWithAssetsManager:(MVAssetsManager*)assetsManager;
- (MVAsset*)uploadFileWithKey:(NSString*)key
                          data:(NSData*)data;
- (MVAsset*)uploadAvatar:(NSData*)data;

@end
