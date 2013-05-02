#import "MVShadow.h"

@implementation MVShadow

- (void)setShadowBlurRadius:(CGFloat)val
{
  [super setShadowBlurRadius:val * [NSScreen mainScreen].backingScaleFactor];
}

- (void)setShadowOffset:(NSSize)offset
{
  CGFloat factor = [NSScreen mainScreen].backingScaleFactor;
  [super setShadowOffset:CGSizeMake(offset.width * factor,
                                    offset.height * factor)];
}

@end
