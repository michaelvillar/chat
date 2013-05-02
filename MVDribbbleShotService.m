#import "MVDribbbleShotService.h"
#import "MVJSONGetRequest.h"

@interface MVDribbbleShotService ()

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSString *shotId;
@property (strong, readwrite) NSString *title;
@property (strong, readwrite) NSURL *imageUrl;
@property (strong, readwrite) NSURL *playerAvatarUrl;
@property (strong, readwrite) NSString *playerName;
@property (strong, readwrite) NSURL *playerUrl;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVDribbbleShotService

@synthesize url                 = url_,
            shotId              = shotId_,
            title               = title_,
            imageUrl            = imageUrl_,
            playerAvatarUrl     = playerAvatarUrl_,
            playerName          = playerName_,
            playerUrl           = playerUrl_,
            informationFetched  = informationFetched_,
            error               = error_;

- (id)initWithURL:(NSURL*)url
           shotId:(NSString*)shotId
{
  self = [super init];
  if(self)
  {
    url_ = url;
    shotId_ = shotId;
    title_ = nil;
    imageUrl_ = nil;
    playerAvatarUrl_ = nil;
    playerName_ = nil;
    playerUrl_ = nil;
    informationFetched_ = NO;
    error_ = NO;
  }
  return self;
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  NSString *urlString = [NSString stringWithFormat:@"http://api.dribbble.com/shots/%@",
                         self.shotId];
  NSURL *url = [NSURL URLWithString:urlString];
  MVJSONGetRequest *getRequest = [[MVJSONGetRequest alloc] initWithURL:url];
  [getRequest get:^(NSObject *object) {
    @try {
      NSDictionary *dictionary = (NSDictionary*)object;
      if(dictionary && [dictionary valueForKey:@"title"])
      {
        self.title = [dictionary valueForKey:@"title"];
        NSString *imageUrlString = [dictionary valueForKey:@"image_url"];
        self.imageUrl = [NSURL URLWithString:imageUrlString];

        NSDictionary *player = [dictionary valueForKey:@"player"];
        NSString *playerAvatarUrlString = [player valueForKey:@"avatar_url"];
        self.playerAvatarUrl = [NSURL URLWithString:playerAvatarUrlString];

        self.playerName = [player valueForKey:@"name"];

        NSString *playerUrlString = [player valueForKey:@"url"];
        self.playerUrl = [NSURL URLWithString:playerUrlString];
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

+ (MVDribbbleShotService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"dribbble.com"] || [url.host isEqualToString:@"www.dribbble.com"])
  {
    NSString *pattern = @"\\/shots\\/([0-9]*)-?";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                        options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:url.path
                                      options:0
                                        range:NSMakeRange(0, url.path.length)];

    if(matches.count == 1)
    {
      NSTextCheckingResult *match = [matches objectAtIndex:0];
      NSRange shotIdRange = [match rangeAtIndex:1];
      NSString *shotId = [url.path substringWithRange:shotIdRange];
      if(shotId.length > 0)
      {
        MVDribbbleShotService *service = [[MVDribbbleShotService alloc] initWithURL:url
                                                                               shotId:shotId];
        return service;
      }
    }
  }
  else if([url.host isEqualToString:@"drbl.in"] || [url.host isEqualToString:@"www.drbl.in"])
  {
    NSString *pattern = @"\\/(.*)?";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:url.path
                                      options:0
                                        range:NSMakeRange(0, url.path.length)];

    if(matches.count == 1)
    {
      NSTextCheckingResult *match = [matches objectAtIndex:0];
      NSRange shotIdRange = [match rangeAtIndex:1];
      NSString *shotId = [url.path substringWithRange:shotIdRange];
      if(shotId.length > 0)
      {
        MVDribbbleShotService *service = [[MVDribbbleShotService alloc] initWithURL:url
                                                                               shotId:shotId];
        return service;
    }
    }
  }
  return nil;
}

@end
