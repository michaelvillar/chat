#import "MVService.h"

@interface MVYoutubeVideoService : NSObject <MVService>

@property (strong, readonly) NSString *title;
@property (strong, readonly) NSURL *thumbnailUrl;

- (id)initWithURL:(NSURL*)url
          videoId:(NSString*)videoId;

@end
