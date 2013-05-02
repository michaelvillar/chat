#import "MVImageService.h"

@interface MVImageService ()

@property (readwrite) BOOL informationFetched;
@property (strong, readwrite) NSURL *url;

@end

@implementation MVImageService

@synthesize informationFetched          = informationFetched_,
            url                         = url_;

- (id)initWithURL:(NSURL*)url
{
  self = [super init];
  if(self)
  {
    url_ = url;
    informationFetched_ = NO;
  }
  return self;
}

- (BOOL)error
{
  return NO;
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  self.informationFetched = YES;
}

+ (MVImageService*)serviceForURL:(NSURL*)url;
{
  NSSet *extensions = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"bmp", @"gif", nil];
  if([extensions containsObject:url.absoluteString.pathExtension.lowercaseString])
  {
    MVImageService *service = [[MVImageService alloc] initWithURL:url];
    return service;
  }
  return nil;
}

@end
