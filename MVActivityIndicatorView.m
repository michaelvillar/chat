#import "MVActivityIndicatorView.h"

@interface MVActivityIndicatorView ()

@property (strong, readwrite) TUIView *overView;
@property (strong, readwrite) TUIView *maskView;
@property (readwrite) BOOL animating;

@end

@implementation MVActivityIndicatorView

@synthesize overView      = overView_,
            maskView      = maskView_,
            animating     = animating_,
            style         = style_;

- (id)initWithFrame:(CGRect)frame
{
  frame.size.width = 14;
  frame.size.height = 15;
  self = [super initWithFrame:frame];
  if(self)
  {
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];

    animating_ = NO;
    style_ = kMVActivityIndicatorStyleNormal;

    __block __weak MVActivityIndicatorView *weakSelf = self;
    overView_ = [[TUIView alloc] initWithFrame:self.bounds];
    overView_.opaque = NO;
    overView_.backgroundColor = [TUIColor clearColor];
    overView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      [[TUIImage imageNamed:((weakSelf.style == kMVActivityIndicatorStyleNormal ||
                              weakSelf.style == kMVActivityIndicatorStyleBottomBar) ?
                             @"icon_activity_indicator_over.png" :
                             @"icon_activity_indicator_over_blue.png")
                      cache:YES] drawAtPoint:CGPointZero];
    };
    [self addSubview:overView_];

    maskView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 1, 14, 14)];
    maskView_.opaque = NO;
    maskView_.backgroundColor = [TUIColor clearColor];
    maskView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      [[TUIImage imageNamed:@"icon_activity_indicator_mask.png" cache:YES]
                                                                    drawAtPoint:CGPointZero];
      [[NSColor colorWithDeviceWhite:0 alpha:0.3] set];
      [NSBezierPath fillRect:view.bounds];
    };
    overView_.layer.mask = maskView_.layer;
  }
  return self;
}

- (void)startAnimating
{
  if(self.animating)
    return;
  self.animating = YES;
  [maskView_.layer removeAllAnimations];

  CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
  animation.values = [NSArray arrayWithObjects:
                      [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0, 0, 0, 1)],
                      [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.14, 0, 0, 1)],
                      [NSValue valueWithCATransform3D:CATransform3DMakeRotation(2*3.14, 0, 0, 1)],
                      nil];
  animation.repeatCount = INT_MAX;
  animation.duration = 1;
  [maskView_.layer addAnimation:animation
                         forKey:@"transform"];
}

- (void)stopAnimating
{
  if(!self.animating)
    return;
  self.animating = NO;
  [maskView_.layer removeAllAnimations];
}

- (void)drawRect:(CGRect)rect
{
  [[TUIImage imageNamed:(self.style == kMVActivityIndicatorStyleBottomBar ?
                         @"icon_activity_indicator_highlight_bottom_bar.png" :
                         @"icon_activity_indicator_highlight.png")
                  cache:YES] drawAtPoint:CGPointZero];
}

@end
