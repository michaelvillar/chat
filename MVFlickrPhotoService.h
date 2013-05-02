#import "MVService.h"

@interface MVFlickrPhotoService : NSObject <MVService>

@property (strong, readonly) NSString *title;
@property (strong, readonly) NSURL *imageUrl;

- (id)initWithURL:(NSURL*)url
          photoId:(long long)photoId;

@end
