#import "MVTopBarView.h"
#import "MVGraphicsFunctions.h"

@implementation MVTopBarView

@synthesize leftBorder          = leftBorder_,
            leftBorderGradient  = leftBorderGradient_;

- (void)drawRect:(CGRect)rect
{
  [[NSGraphicsContext currentContext] saveGraphicsState];

  NSColor *startColor;
  NSColor *endColor;

  startColor = [NSColor colorWithDeviceRed:0.8941 green:0.8941 blue:0.9020 alpha:1.0000];
  endColor = [NSColor colorWithDeviceRed:0.9686 green:0.9686 blue:0.9765 alpha:1.0000];
  NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
  [gradient drawInRect:CGRectMake(0, 1, self.bounds.size.width, self.bounds.size.height - 2) angle:90];

  [[NSColor colorWithDeviceRed:0.9922 green:0.9922 blue:0.9961 alpha:1.0000] set];
  [NSBezierPath fillRect:CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1)];

  [[NSColor colorWithDeviceRed:0.7216 green:0.7216 blue:0.7490 alpha:1.0000] set];
  [NSBezierPath fillRect:CGRectMake(0, 0, self.bounds.size.width, 1)];

  if(self.leftBorder && self.leftBorderGradient)
  {
    startColor = [NSColor colorWithDeviceRed:0.7098 green:0.7098 blue:0.7333 alpha:1];
    endColor = [NSColor colorWithDeviceRed:0.7098 green:0.7098 blue:0.7333 alpha:0];
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:CGRectMake(0, 1, 1, self.bounds.size.height - 4) angle:90];

    startColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
    endColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.0];
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:CGRectMake(1, 1, 1, self.bounds.size.height - 1) angle:90];
  }
  else if(self.leftBorder)
  {
    [kMVSplitViewBorderColor set];
    NSRectFill(CGRectMake(0, 0, 1, self.bounds.size.height));
  }

  [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
