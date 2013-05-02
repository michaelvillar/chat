#import "MVService.h"

@interface MVImageService : NSObject <MVService>

@property (strong, readonly) NSURL *url;

- (id)initWithURL:(NSURL*)url;

@end
