#import "MVKickoffFileService.h"

@interface MVKickoffFileService ()

@property (readwrite) BOOL informationFetched;
@property (strong, readwrite) NSURL *url;

@end

@implementation MVKickoffFileService

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

+ (MVKickoffFileService*)serviceForURL:(NSURL*)url;
{
  NSArray *buckets = [NSArray arrayWithObjects:
                      @"kickoff2dev",
                      @"kickoff2staging",
                      @"kickoff",
                      @"kickoff2",
                      @"kickoff2prod",
                      nil];
  NSMutableArray *hosts = [NSMutableArray array];
  NSString *bucket;
  for(bucket in buckets)
  {
    [hosts addObject:[NSString stringWithFormat:@"%@.s3.amazonaws.com", bucket]];
  }

  if(([url.host isEqualToString:@"s3.amazonaws.com"] &&
      url.pathComponents.count > 1 &&
      [buckets containsObject:[url.pathComponents objectAtIndex:1]]) ||
     [hosts containsObject:url.host])
  {
    MVKickoffFileService *service = [[MVKickoffFileService alloc] initWithURL:url];
    return service;
  }
  return nil;
}

@end
