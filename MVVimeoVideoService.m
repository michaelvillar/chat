#import "MVVimeoVideoService.h"
#import "MVJSONGetRequest.h"

@interface MVVimeoVideoService ()

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSString *videoId;
@property (strong, readwrite) NSString *title;
@property (strong, readwrite) NSURL *thumbnailUrl;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVVimeoVideoService

@synthesize url                 = url_,
            videoId             = videoId_,
            title               = title_,
            thumbnailUrl        = thumbnailUrl_,
            informationFetched  = informationFetched_,
            error               = error_;

- (id)initWithURL:(NSURL*)url
          videoId:(NSString*)videoId
{
  self = [super init];
  if(self)
  {
    url_ = url;
    videoId_ = videoId;
    title_ = nil;
    thumbnailUrl_ = nil;
    informationFetched_ = NO;
    error_ = NO;
  }
  return self;
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  NSString *urlString = [NSString stringWithFormat:
                         @"http://vimeo.com/api/v2/video/%@.json",
                         self.videoId];
  NSURL *url = [NSURL URLWithString:urlString];
  MVJSONGetRequest *getRequest = [[MVJSONGetRequest alloc] initWithURL:url];
  [getRequest get:^(NSObject *json) {
    @try {
      NSArray *videos = (NSArray*)json;
      if(videos && [videos count] == 1)
      {
        NSDictionary *dictionary = (NSDictionary*)([videos objectAtIndex:0]);

        NSString *thumbnailUrlString = [dictionary valueForKey:@"thumbnail_large"];
        self.thumbnailUrl = [NSURL URLWithString:thumbnailUrlString];

        self.title = [dictionary valueForKey:@"title"];
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

+ (MVVimeoVideoService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"vimeo.com"] || [url.host isEqualToString:@"www.vimeo.com"])
  {
    NSString *pattern = @"^\\/([0-9]*)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                        options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:url.path
                                      options:0
                                        range:NSMakeRange(0, url.path.length)];
    if(matches.count == 1)
    {
      NSTextCheckingResult *match = [matches objectAtIndex:0];
      NSRange videoIdRange = [match rangeAtIndex:1];
      NSString *videoId = [url.path substringWithRange:videoIdRange];
      MVVimeoVideoService *service = [[MVVimeoVideoService alloc] initWithURL:url
                                                                        videoId:videoId];
      return service;
    }
  }
  return nil;
}

@end
