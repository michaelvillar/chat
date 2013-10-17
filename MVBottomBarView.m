#import "MVBottomBarView.h"
#import "MVGraphicsFunctions.h"

@interface MVBottomBarView ()

@property (strong, readwrite) TUIView *bottomView;
@property (strong, readwrite) TUIView *topView;

@end

@implementation MVBottomBarView

@synthesize bottomView                = bottomView_,
            topView                   = topView_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];
    self.clipsToBounds = YES;

    bottomView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0,
                                                            frame.size.width,
                                                            22)];
    bottomView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    bottomView_.opaque = NO;
    bottomView_.backgroundColor = [TUIColor clearColor];
    bottomView_.shouldDisplayWhenWindowChangesFocus = YES;
    bottomView_.drawRect = ^(TUIView *view, CGRect rect) {
      [[NSColor colorWithDeviceWhite:1 alpha:0.8] set];
      
      float radius = 5;
      rect = view.bounds;
      NSBezierPath *path = [NSBezierPath bezierPath];
      [path moveToPoint:CGPointMake(rect.size.width, rect.size.height / 2)];
      [path appendBezierPathWithArcFromPoint:CGPointMake(rect.size.width, 0)
                                     toPoint:CGPointMake(rect.size.width / 2, 0)
                                      radius:radius];
      [path appendBezierPathWithArcFromPoint:CGPointMake(0, 0)
                                     toPoint:CGPointMake(0, rect.size.height / 2)
                                      radius:radius];
      [path lineToPoint:CGPointMake(0, rect.size.height)];
      [path lineToPoint:CGPointMake(rect.size.width, rect.size.height)];
      [path closePath];
      [path fill];
    };

    topView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, frame.size.height - 8,
                                                         frame.size.width,
                                                         8)];
    topView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                TUIViewAutoresizingFlexibleBottomMargin;
    topView_.opaque = NO;
    topView_.backgroundColor = [TUIColor clearColor];
    topView_.shouldDisplayWhenWindowChangesFocus = YES;
    topView_.drawRect = ^(TUIView* view, CGRect rect) {
      NSColor *startColor = [NSColor colorWithDeviceWhite:1 alpha:0.8];
      NSColor *endColor = [NSColor colorWithDeviceWhite:1 alpha:0];
      NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                              endColor, 0.0,
                              startColor, 1.0,
                              nil];
      [gradient drawFromPoint:CGPointMake(0, view.bounds.size.height)
                      toPoint:CGPointMake(0, 0) options:0];
    };

    [self addSubview:bottomView_];
    [self addSubview:topView_];
  }
  return self;
}

- (void)setFrame:(CGRect)frame
{
  CGRect oldFrame = self.frame;
  [super setFrame:frame];

  if((oldFrame.size.height > 30) != (frame.size.height > 30)) {
    [self.topView setNeedsDisplay];
  }
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
  [self.bottomView setNeedsDisplay];
  [self.topView setNeedsDisplay];
}

@end
