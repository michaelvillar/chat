#import "MVCloudAppLinkService.h"
#import "MVJSONGetRequest.h"

@interface MVCloudAppLinkService ()

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSString *token;
@property (strong, readwrite) NSString *name;
@property (strong, readwrite) NSString *itemType;
@property (strong, readwrite) NSURL *downloadUrl;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVCloudAppLinkService

@synthesize url                 = url_,
            token               = token_,
            name                = name_,
            itemType            = itemType_,
            downloadUrl         = downloadUrl_,
            informationFetched  = informationFetched_,
            error               = error_;

- (id)initWithURL:(NSURL*)url
            token:(NSString*)token
{
  self = [super init];
  if(self)
  {
    url_ = url;
    token_ = token;
    name_ = nil;
    itemType_ = nil;
    downloadUrl_ = nil;
    informationFetched_ = NO;
    error_ = NO;
  }
  return self;
}

 - (BOOL)isImage
{
  return [self.itemType isEqualToString:@"image"];
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  NSString *urlString = [NSString stringWithFormat:@"http://cl.ly/%@",self.token];
  NSURL *url = [NSURL URLWithString:urlString];
  MVJSONGetRequest *getRequest = [[MVJSONGetRequest alloc] initWithURL:url];
  [getRequest get:^(NSObject *object) {
    @try {
      NSDictionary *dictionary = (NSDictionary*)object;
      if(dictionary && [dictionary valueForKey:@"name"] && [dictionary valueForKey:@"download_url"])
      {
        self.name = [dictionary valueForKey:@"name"];
        self.itemType = [dictionary valueForKey:@"item_type"];
        NSString *downloadUrlString = [dictionary valueForKey:@"download_url"];
        self.downloadUrl = [NSURL URLWithString:downloadUrlString];
      }
      else
      {
        self.error = YES;
      }
    }
    @catch (NSException *exception) {
      self.error = YES;
    }

    self.informationFetched = YES;
  }];
}

+ (MVCloudAppLinkService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"cl.ly"])
  {
    MVCloudAppLinkService *service = [[MVCloudAppLinkService alloc] initWithURL:url
                                                                            token:url.path];
    return service;
  }
  return nil;
}

@end
