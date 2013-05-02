#import "TUIImage+ProportionalResize.h"

@implementation TUIImage (ProportionalResize)

- (TUIImage*)proportionalScaleWithMaxSize:(CGSize)maxSize
{
  CGSize currentSize = self.size;
  CGSize newSize = CGSizeZero;
  float currentRatio = currentSize.width / currentSize.height;
  if(maxSize.width / currentSize.width > 1 && maxSize.height / currentSize.height > 1)
    return self;
  if(maxSize.width / currentSize.width < 1 &&
     maxSize.width / currentSize.width > maxSize.height / currentSize.height)
  {
    newSize.width = maxSize.width;
    newSize.height = newSize.width / currentRatio;
  }
  else
  {
    newSize.height = maxSize.height;
    newSize.width = newSize.height * currentRatio;
  }
  return [self scale:newSize];
}

@end
