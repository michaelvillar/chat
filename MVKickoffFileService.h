#import <Foundation/Foundation.h>
#import "MVService.h"

@interface MVKickoffFileService : NSObject <MVService>

@property (strong, readonly) NSURL *url;

- (id)initWithURL:(NSURL*)url;

@end
