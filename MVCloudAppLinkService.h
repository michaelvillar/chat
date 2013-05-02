#import "MVService.h"

@interface MVCloudAppLinkService : NSObject <MVService>

@property (strong, readonly) NSString *name;
@property (readonly, getter = isImage, nonatomic) BOOL image;
@property (strong, readonly) NSURL *downloadUrl;

- (id)initWithURL:(NSURL*)url
            token:(NSString*)token;
@end
