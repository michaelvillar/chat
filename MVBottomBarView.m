#import "MVBottomBarView.h"
#import "MVGraphicsFunctions.h"

#define MV_COLOR_MAIN_START [NSColor colorWithDeviceRed:0.6745 green:0.6745 blue:0.6745 alpha:1]
#define MV_COLOR_MAIN_END [NSColor colorWithDeviceRed:0.9098 green:0.9098 blue:0.9098 alpha:1]
#define MV_COLOR_MAIN_TOP_BORDER [NSColor colorWithDeviceRed:0.6627 green:0.6784 blue:0.7137 alpha:1]
#define MV_COLOR_MAIN_TOP_HIGHLIGHT [NSColor colorWithDeviceRed:0.9725 green:0.9725 blue:0.9725 alpha:1]
#define MV_COLOR_MAIN_INTER [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.2]
#define MV_COLOR_MAIN_INTER_HIGHLIGHT_BOTTOM [NSColor colorWithCalibratedWhite:1 alpha:0.5]
#define MV_COLOR_MAIN_INTER_HIGHLIGHT_TOP [NSColor colorWithCalibratedWhite:1 alpha:0.15]

#define MV_COLOR_NOTMAIN_START [NSColor colorWithDeviceRed:0.8392 green:0.8392 blue:0.8392 alpha:1]
#define MV_COLOR_NOTMAIN_END [NSColor colorWithDeviceRed:0.9529 green:0.9529 blue:0.9529 alpha:1]
#define MV_COLOR_NOTMAIN_TOP_BORDER [NSColor colorWithDeviceRed:0.7882 green:0.8039 blue:0.8392 alpha:1]
#define MV_COLOR_NOTMAIN_INTER [NSColor colorWithDeviceRed:0.8078 green:0.8078 blue:0.8078 alpha:1]

@interface MVBottomBarView ()

@property (strong, readwrite) TUIView *bottomView;
@property (strong, readwrite) TUIView *topView;
@property (strong, readwrite) TUIView *backgroundView;

@end

@implementation MVBottomBarView

@synthesize bottomView                = bottomView_,
            topView                   = topView_,
            backgroundView            = backgroundView_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    __block MVBottomBarView *parent = self;

    self.backgroundColor = [TUIColor blackColor];
    self.clipsToBounds = YES;

    backgroundView_ = [[TUIView alloc] initWithFrame:self.bounds];
    backgroundView_.shouldDisplayWhenWindowChangesFocus = YES;
    backgroundView_.drawRect = ^(TUIView *view, CGRect rect) {
      [NSGraphicsContext saveGraphicsState];
      [(view.windowHasFocus ? MV_COLOR_MAIN_END : MV_COLOR_NOTMAIN_END) set];
      [NSBezierPath fillRect:CGRectMake(0, 5, rect.size.width, rect.size.height - 5)];

      // noise
      static CGImageRef noisePattern = nil;
      if (noisePattern == nil) noisePattern = MVCreateNoiseImageRef(128, 128, 0.015);
      [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
      CGRect noisePatternRect = CGRectZero;
      noisePatternRect.size = CGSizeMake(CGImageGetWidth(noisePattern),
                                         CGImageGetHeight(noisePattern));
      CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
      CGContextDrawTiledImage(context, noisePatternRect, noisePattern);
      [NSGraphicsContext restoreGraphicsState];
    };

    bottomView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0,
                                                            frame.size.width,
                                                            29)];
    bottomView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    bottomView_.backgroundColor = [TUIColor clearColor];
    bottomView_.shouldDisplayWhenWindowChangesFocus = YES;
    bottomView_.drawRect = ^(TUIView *view, CGRect rect) {
      rect = view.bounds;

      [NSGraphicsContext saveGraphicsState];
      // clipping mask
      float radius = 3.5;
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
      [path addClip];

      // gradient
      NSColor *startColor = view.windowHasFocus ? MV_COLOR_MAIN_START : MV_COLOR_NOTMAIN_START;
      NSColor *endColor = view.windowHasFocus ? MV_COLOR_MAIN_END : MV_COLOR_NOTMAIN_END;
      NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
      [gradient drawInRect:CGRectMake(0, 0, view.bounds.size.width, 29) angle:90];

      // noise
      static CGImageRef noisePattern = nil;
      if (noisePattern == nil) noisePattern = MVCreateNoiseImageRef(128, 128, 0.015);
      [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
      CGRect noisePatternRect = CGRectZero;
      noisePatternRect.size = CGSizeMake(CGImageGetWidth(noisePattern),
                                         CGImageGetHeight(noisePattern));
      CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
      CGContextDrawTiledImage(context, noisePatternRect, noisePattern);
      [NSGraphicsContext restoreGraphicsState];
    };

    topView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, frame.size.height - 8,
                                                         frame.size.width,
                                                         8)];
    topView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                TUIViewAutoresizingFlexibleBottomMargin;
    topView_.backgroundColor = [TUIColor clearColor];
    topView_.shouldDisplayWhenWindowChangesFocus = YES;
    topView_.drawRect = ^(TUIView* view, CGRect rect) {
      [[NSGraphicsContext currentContext] saveGraphicsState];

      // top border
      [(view.windowHasFocus ? MV_COLOR_MAIN_TOP_BORDER : MV_COLOR_NOTMAIN_TOP_BORDER) set];
      CGRect topBorderRect = CGRectMake(0, 7, rect.size.width, 1);
      NSRectFill(topBorderRect);

      // top highlight
      [MV_COLOR_MAIN_TOP_HIGHLIGHT set];
      CGRect topHighlightRect = CGRectMake(0, 6, rect.size.width, 1);
      NSRectFill(topHighlightRect);

      if(parent.bounds.size.height > 30) {
        // second gradient
        NSColor *startColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
        NSColor *endColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.7];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor
                                                             endingColor:endColor];
        [gradient drawInRect:CGRectMake(0, 0, view.bounds.size.width, 7) angle:90];
      }

      [[NSGraphicsContext currentContext] restoreGraphicsState];
    };

    [self addSubview:backgroundView_];
    [self addSubview:bottomView_];
    [self addSubview:topView_];

//    self.moveWindowByDragging = YES;
//    bottomView_.moveWindowByDragging = YES;
//    topView_.moveWindowByDragging = YES;
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

- (void)layoutSubviews
{
  [super layoutSubviews];

  if(!CGRectContainsRect(self.backgroundView.frame, self.bounds)) {
    [self.backgroundView setFrame:CGRectMake(0, 0,
                                             self.bounds.size.width * 2,
                                             self.bounds.size.height + 800)];
  }
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
  [self.backgroundView setNeedsDisplay];
  [self.bottomView setNeedsDisplay];
  [self.topView setNeedsDisplay];
}

@end
