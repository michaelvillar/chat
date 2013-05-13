#import <Foundation/Foundation.h>

#define kMVUploadAuthorizationServiceS3 @"s3"
#define kMVUploadAuthorizationServiceCloudApp @"cloudapp"

@interface MVUploadAuthorization : NSObject

@property (strong, readonly) NSString *service;

// S3
@property (strong, readonly) NSString *bucket;
@property (strong, readonly) NSString *uploadURL;
@property (strong, readonly) NSString *accessKeyId;
@property (strong, readonly) NSString *startsWith;
@property (strong, readonly) NSString *acl;
@property (strong, readonly) NSString *successActionRedirect;
@property (readonly) long long maximumSizeInBytes;
@property (strong, readonly) NSString *policy;
@property (strong, readonly) NSString *signature;
@property (strong, readonly) NSDate *expirationDate;
@property (readonly, getter = isExpired) BOOL expired;

// CloudApp
@property (strong, readonly) NSString *email;
@property (strong, readonly) NSString *password;

- (id)initWithService:(NSString*)service
               bucket:(NSString*)bucket
            uploadURL:(NSString*)uploadURL
          accessKeyId:(NSString*)accessKeyId
           startsWith:(NSString*)startsWith
                  acl:(NSString*)acl
successActionRedirect:(NSString*)successActionRedirect
   maximumSizeInBytes:(long long)maximumSizeInBytes
               policy:(NSString*)policy
            signature:(NSString*)signature
       expirationDate:(NSDate*)expirationDate;
- (id)initWithCloudAppEmail:(NSString*)email
                   password:(NSString*)password;

@end
