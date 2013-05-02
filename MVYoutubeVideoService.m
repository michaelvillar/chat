#import "MVYoutubeVideoService.h"
#import "MVJSONGetRequest.h"
#import "NSString+QueryParsing.h"

@interface MVYoutubeVideoService ()

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSString *videoId;
@property (strong, readwrite) NSString *title;
@property (strong, readwrite) NSURL *thumbnailUrl;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVYoutubeVideoService

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
                         @"http://gdata.youtube.com/feeds/api/videos/%@?v=2&alt=jsonc",
                         self.videoId];
  NSURL *url = [NSURL URLWithString:urlString];
  MVJSONGetRequest *getRequest = [[MVJSONGetRequest alloc] initWithURL:url];
  [getRequest get:^(NSObject *object) {
    @try {
      NSDictionary *dictionary = (NSDictionary*)object;
      if(dictionary && [dictionary valueForKey:@"data"])
      {
        NSDictionary *dataDic = [dictionary valueForKey:@"data"];
        NSString *thumbnailUrlString = [[dataDic valueForKey:@"thumbnail"] valueForKey:@"hqDefault"];
        self.thumbnailUrl = [NSURL URLWithString:thumbnailUrlString];

        self.title = [dataDic valueForKey:@"title"];
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

+ (MVYoutubeVideoService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"youtube.com"] || [url.host isEqualToString:@"www.youtube.com"] ||
     [url.host isEqualToString:@"youtu.be"] || [url.host isEqualToString:@"www.youtu.be"])
  {
    BOOL shortened = ([url.host isEqualToString:@"youtu.be"] ||
                      [url.host isEqualToString:@"www.youtu.be"]);
    NSString *pattern = @"\\/watch\\?(.*)?";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:url.absoluteString
                                      options:0
                                        range:NSMakeRange(0, url.absoluteString.length)];
    if(matches.count == 1 || shortened)
    {
      NSString *videoId = nil;
      if(shortened)
      {
        videoId = [url.path substringFromIndex:1];
      }
      else
      {
        NSDictionary *components = url.query.dictionaryFromQueryComponents;
        if([components valueForKey:@"v"] &&
           [[components valueForKey:@"v"] isKindOfClass:[NSArray class]] &&
           ((NSArray*)([components valueForKey:@"v"])).count == 1)
        {
          videoId = [[components valueForKey:@"v"] objectAtIndex:0];
        }
      }

      if(videoId)
      {
        MVYoutubeVideoService *service = [[MVYoutubeVideoService alloc] initWithURL:url
                                                                              videoId:videoId];
        return service;
      }
    }
  }
  return nil;
}

@end
