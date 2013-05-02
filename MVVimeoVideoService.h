#import "MVService.h"

@interface MVVimeoVideoService : NSObject <MVService>

@property (strong, readonly) NSString *title;
@property (strong, readonly) NSURL *thumbnailUrl;

- (id)initWithURL:(NSURL*)url
          videoId:(NSString*)videoId;
@end
