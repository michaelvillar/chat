#import "MVCircleLoaderView.h"
#import "MVGraphicsFunctions.h"
#import "MVShadow.h"

@implementation MVCircleLoaderView

@synthesize percentage            = percentage_,
            style                 = style_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];
    self.userInteractionEnabled = NO;

    percentage_ = 0;
    style_ = kMVCircleLoaderStyleWhite;
  }
  return self;
}

- (void)setPercentage:(float)percentage
{
  if(percentage > 100)
    percentage = 100;
  else if(percentage < 0)
    percentage = 0;
  percentage_ = percentage;
}

- (void)drawRect:(CGRect)rect
{
  [[NSGraphicsContext currentContext] saveGraphicsState];
  NSShadow *shadow = [[MVShadow alloc] init];
  if(self.style == kMVCircleLoaderStyleWhite)
  {
    shadow.shadowColor = [NSColor colorWithDeviceWhite:0 alpha:0.55];
    shadow.shadowBlurRadius = 1.5;
    shadow.shadowOffset = CGSizeMake(0, 0);
  }
  else
  {
    if(self.style == kMVCircleLoaderStyleEmbossedBlue)
      shadow.shadowColor = [NSColor colorWithDeviceRed:0.8627 green:0.9333
                                                  blue:1.0000 alpha:1.0000];
    else if(self.style == kMVCircleLoaderStyleEmbossedGrey)
      shadow.shadowColor = [NSColor whiteColor];
    shadow.shadowBlurRadius = 0;
    shadow.shadowOffset = CGSizeMake(0, -1);
  }
  [shadow set];

  CGRect circleRect = CGRectInset(self.bounds, 3.1, 3.1);
  CGRect innerCircleRect = CGRectInset(circleRect, 1.8, 1.8);
  CGPoint centerPoint = CGPointMake(NSMidX(circleRect), NSMidY(circleRect));

  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:CGPointMake(NSMaxX(circleRect), NSMidY(circleRect))];
  [path appendBezierPathWithArcWithCenter:centerPoint
                                   radius:circleRect.size.width / 2
                               startAngle:0 endAngle:180];
  [path appendBezierPathWithArcWithCenter:centerPoint
                                   radius:circleRect.size.width / 2
                               startAngle:180 endAngle:360];
  NSBezierPath *fullPath;

  if(self.percentage < 100)
  {
    [path lineToPoint:CGPointMake(NSMaxX(innerCircleRect), NSMidY(innerCircleRect))];
    [path appendBezierPathWithArcWithCenter:centerPoint
                                     radius:innerCircleRect.size.width / 2
                                 startAngle:360 endAngle:0 clockwise:YES];
    [path closePath];

    NSBezierPath *progressPath = [NSBezierPath bezierPath];
    [progressPath moveToPoint:centerPoint];
    [progressPath appendBezierPathWithArcWithCenter:centerPoint
                                             radius:(circleRect.size.height - 2) / 2
                                         startAngle:90 + (360 - self.percentage * 3.6)
                                           endAngle:90];
    [progressPath closePath];

    fullPath = [NSBezierPath bezierPath];
    [fullPath appendBezierPath:progressPath];
    [fullPath appendBezierPath:path];
    [fullPath closePath];
  }
  else
  {
    fullPath = path;
  }

  if(self.style == kMVCircleLoaderStyleWhite)
    [[NSColor whiteColor] set];
  else if(self.style == kMVCircleLoaderStyleEmbossedBlue)
    [[NSColor colorWithDeviceRed:0.5725 green:0.6980 blue:0.8588 alpha:1.0000] set];
  else if(self.style == kMVCircleLoaderStyleEmbossedGrey)
    [[NSColor colorWithDeviceRed:0.7804 green:0.8078 blue:0.8588 alpha:1.0000] set];
  [fullPath fill];

  [[NSGraphicsContext currentContext] restoreGraphicsState];

  if(self.style == kMVCircleLoaderStyleEmbossedBlue ||
     self.style == kMVCircleLoaderStyleEmbossedGrey)
  {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    shadow = [[MVShadow alloc] init];
    [fullPath setClip];
    if(self.style == kMVCircleLoaderStyleEmbossedBlue)
    {
      shadow.shadowColor = [NSColor colorWithDeviceRed:0.3098 green:0.4627
                                                  blue:0.7961 alpha:1];
    }
    else if(self.style == kMVCircleLoaderStyleEmbossedGrey)
    {
      shadow.shadowColor = [NSColor colorWithDeviceRed:0.3725 green:0.4157
                                                  blue:0.4980 alpha:0.75];
    }

    shadow.shadowBlurRadius = 1;
    shadow.shadowOffset = NSMakeSize(0, -1);
    [shadow set];

    [shadow.shadowColor set];

    NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    circlePath.lineWidth = 0.5;
    [circlePath stroke];

    NSBezierPath *innerProgressionPath = [NSBezierPath bezierPath];
    [innerProgressionPath moveToPoint:centerPoint];
    [innerProgressionPath appendBezierPathWithArcWithCenter:centerPoint
                                                     radius:(innerCircleRect.size.height - 0.5) / 2
                                                 startAngle:90
                                                   endAngle:90 + (360 - self.percentage * 3.6)];
    [innerProgressionPath closePath];
    [innerProgressionPath fill];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }
}

@end
