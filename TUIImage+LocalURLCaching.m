#import "TUIImage+LocalURLCaching.h"

@implementation TUIImage (LocalURLCaching)

+ (TUIImage*)imageWithContentsOfURL:(NSURL*)url cache:(BOOL)shouldCache
{
  if(!url)
		return nil;

	static NSMutableDictionary *cache = nil;
	if(!cache) {
		cache = [[NSMutableDictionary alloc] init];
	}

	TUIImage *image = [cache objectForKey:url.absoluteString];
	if(image)
		return image;

  NSData *data = [NSData dataWithContentsOfURL:url];
  if(data) {
    image = [self imageWithData:data];
    if(image) {
      if(shouldCache) {
        [cache setObject:image forKey:url.absoluteString];
      }
    }
  }

	return image;
}

@end
