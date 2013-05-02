#import "MVUploadAuthorization.h"

@interface MVUploadAuthorization ()

@property (strong, readwrite) NSString *service;
@property (strong, readwrite) NSString *bucket;
@property (strong, readwrite) NSString *uploadURL;
@property (strong, readwrite) NSString *accessKeyId;
@property (strong, readwrite) NSString *startsWith;
@property (strong, readwrite) NSString *acl;
@property (strong, readwrite) NSString *successActionRedirect;
@property (readwrite) long long maximumSizeInBytes;
@property (strong, readwrite) NSString *policy;
@property (strong, readwrite) NSString *signature;
@property (strong, readwrite) NSDate *expirationDate;

@end

@implementation MVUploadAuthorization

@synthesize service             = service_,
            bucket              = bucket_,
            uploadURL           = uploadURL_,
            accessKeyId         = accessKeyId_,
            startsWith          = startsWith_,
            acl                 = acl_,
            successActionRedirect = successActionRedirect_,
            maximumSizeInBytes  = maximumSizeInBytes_,
            policy              = policy_,
            signature           = signature_,
            expirationDate      = expirationDate_;

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
       expirationDate:(NSDate*)expirationDate
{
  self = [super init];
  if(self)
  {
    NSAssert([service isEqualToString:kMVUploadAuthorizationServiceS3],
             @"kMVUploadAuthorizationServiceS3 service is only supported");
    service_ = service;
    bucket_ = bucket;
    uploadURL_ = uploadURL;
    accessKeyId_ = accessKeyId;
    startsWith_ = startsWith;
    acl_ = acl;
    successActionRedirect_ = successActionRedirect;
    maximumSizeInBytes_ = maximumSizeInBytes;
    policy_ = policy;
    signature_ = signature;
    expirationDate_ = expirationDate;
  }
  return self;
}

- (BOOL)isExpired
{
  return [self.expirationDate compare:[NSDate date]] != NSOrderedDescending;
}

@end
