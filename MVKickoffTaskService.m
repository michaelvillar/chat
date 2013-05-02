#import "MVKickoffTaskService.h"

@interface MVKickoffTaskService ()

@property (readwrite) BOOL informationFetched;
@property (strong, readwrite) NSURL *url;

@end

@implementation MVKickoffTaskService

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

+ (MVKickoffTaskService*)serviceForURL:(NSURL*)url;
{
  NSArray *hosts = [NSArray arrayWithObjects:
                    @"apiv2.kickoffapp.com",
                    @"apiv2staging.kickoffapp.com",
                    nil];
  if([hosts containsObject:url.host])
  {
    NSString *taskRegex = @"^/teams/(\\d)*/tasks/(\\d)*";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:taskRegex
                                                        options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    NSUInteger nbMatches = [regex numberOfMatchesInString:url.path
                                                  options:0
                                                    range:NSMakeRange(0, url.path.length)];
    if(nbMatches > 0)
    {
      MVKickoffTaskService *service = [[MVKickoffTaskService alloc] initWithURL:url];
      return service;
    }
  }
  return nil;
}

@end
