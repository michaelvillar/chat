#import "MVService.h"

@interface MVDroplrLinkService : NSObject <MVService>

@property (readonly, getter = isImage, nonatomic) BOOL image;
@property (strong, readonly) NSURL *downloadUrl;

- (id)initWithURL:(NSURL*)url
         itemType:(NSString*)type;

@end
