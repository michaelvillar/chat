#import <Foundation/Foundation.h>
#import "MVService.h"

@interface MVDribbbleShotService : NSObject <MVService>

@property (strong, readonly) NSString *title;
@property (strong, readonly) NSURL *imageUrl;
@property (strong, readonly) NSURL *playerAvatarUrl;
@property (strong, readonly) NSString *playerName;
@property (strong, readonly) NSURL *playerUrl;

- (id)initWithURL:(NSURL*)url
           shotId:(NSString*)shotId;

@end
