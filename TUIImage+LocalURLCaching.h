#import <TwUI/TUIKit.h>

@interface TUIImage (LocalURLCaching)

+ (TUIImage*)imageWithContentsOfURL:(NSURL*)url cache:(BOOL)shouldCache;

@end
