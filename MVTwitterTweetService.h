#import "MVService.h"

@interface MVTwitterTweetService : NSObject <MVService>

@property (strong, readonly) NSString *text;
@property (strong, readonly) NSAttributedString *attributedText;
@property (strong, readonly) NSString *userName;
@property (strong, readonly) NSURL *userImageUrl;
@property (strong, readonly) NSString *userScreenName;
@property (strong, readonly, nonatomic) NSURL *userUrl;

- (id)initWithURL:(NSURL*)url
          tweetId:(long long)tweetId;

@end
