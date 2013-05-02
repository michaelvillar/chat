#import "MVTwitterTweetService.h"
#import "MVJSONGetRequest.h"
#import "NSMutableAttributedString+LinksDetection.h"
#import "NSString+HTMLEntities.h"

@interface MVTwitterTweetService ()

@property (strong, readwrite) NSURL *url;
@property (readwrite) long long tweetId;
@property (strong, readwrite) NSString *text;
@property (strong, readwrite) NSAttributedString *attributedText;
@property (strong, readwrite) NSString *userName;
@property (strong, readwrite) NSURL *userImageUrl;
@property (strong, readwrite) NSString *userScreenName;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVTwitterTweetService

@synthesize url                 = url_,
            tweetId             = tweetId_,
            text                = text_,
            attributedText      = attributedText_,
            userName            = userName_,
            userImageUrl        = userImageUrl_,
            userScreenName      = userScreenName_,
            informationFetched  = informationFetched_,
            error               = error_;

- (id)initWithURL:(NSURL*)url
          tweetId:(long long)tweetId
{
  self = [super init];
  if(self)
  {
    url_ = url;
    tweetId_ = tweetId;
    text_ = nil;
    attributedText_ = nil;
    userName_ = nil;
    userImageUrl_ = nil;
    userScreenName_ = nil;
    informationFetched_ = NO;
    error_ = NO;
  }
  return self;
}

- (NSURL*)userUrl
{
  NSString *userUrlString = [NSString stringWithFormat:@"http://twitter.com/%@",
                             self.userScreenName];
  return [NSURL URLWithString:userUrlString];
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  NSString *urlString = [NSString stringWithFormat:
                         @"http://api.twitter.com/1/statuses/show/%lld.json",
                         self.tweetId];
  NSURL *url = [NSURL URLWithString:urlString];
  MVJSONGetRequest *getRequest = [[MVJSONGetRequest alloc] initWithURL:url];
  [getRequest get:^(NSObject *object) {
    @try {
      NSDictionary *dictionary = (NSDictionary*)object;
      if(dictionary && ![dictionary valueForKey:@"error"] && ![dictionary valueForKey:@"errors"])
      {
        NSDictionary *status = dictionary;
        if([dictionary valueForKey:@"retweeted_status"])
          status = [dictionary valueForKey:@"retweeted_status"];

        NSString *text = [status valueForKey:@"text"];
        if(!text)
          text = @"";
        else
          text = [text decodeHTMLEntities];
        self.text = text;

        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]
                                                     initWithString:self.text];
        [attributedText mv_detectLinks];
        [attributedText mv_detectEmails];
        [attributedText mv_detectTwitterUsernamesAndHashTags];
        self.attributedText = attributedText;

        NSDictionary *user = [status valueForKey:@"user"];
        self.userName = [user valueForKey:@"name"];

        NSString *userImageUrlString = [user valueForKey:@"profile_image_url"];
        self.userImageUrl = [NSURL URLWithString:userImageUrlString];

        self.userScreenName = [user valueForKey:@"screen_name"];
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

+ (MVTwitterTweetService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"twitter.com"] || [url.host isEqualToString:@"www.twitter.com"])
  {
    NSString *pattern = @"\\/(status|statuses)\\/([0-9]*)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                        options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:url.absoluteString
                                      options:0
                                        range:NSMakeRange(0, url.absoluteString.length)];
    if(matches.count == 1)
    {
      NSTextCheckingResult *match = [matches objectAtIndex:0];
      NSRange tweetIdRange = [match rangeAtIndex:2];
      long long tweetId = [[url.absoluteString substringWithRange:tweetIdRange] longLongValue];
      MVTwitterTweetService *service = [[MVTwitterTweetService alloc] initWithURL:url
                                                                            tweetId:tweetId];
      return service;
    }
  }
  return nil;
}

@end
