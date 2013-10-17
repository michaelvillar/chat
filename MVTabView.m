#import "MVTabView.h"
#import "MVGraphicsFunctions.h"
#import "NSObject+PerformBlockAfterDelay.h"

#define kMVTabViewGlowingDuration 0.7

@interface MVTabView ()

@property (readwrite, getter = isHighlighted) BOOL highlighted;
@property (strong, readwrite) TUIView *sortingBackground;
@property (strong, readwrite) TUIView *glowingView;
@property (readwrite) BOOL mouseDown;
@property (readwrite) BOOL mouseDragged;

- (void)updateGlowingAnimation;

@end

void MVTabDraw(MVTabView *view, CGRect rect, BOOL forceGlowing, int glowingPhase);
void MVTabDraw(MVTabView *view, CGRect rect, BOOL forceGlowing, int glowingPhase)
{
  CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [[NSGraphicsContext currentContext] saveGraphicsState];

  CGRect bounds = view.bounds;
  
  if(view.previousTab != nil) {
    [[NSColor colorWithDeviceRed:0.8314 green:0.8510 blue:0.8745 alpha:1.0000] set];
    [NSBezierPath fillRect:CGRectMake(0, 7, 0.5, 9.5)];
    
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:CGRectMake(0, 6.5, 0.5, 0.5)];
  }

  float marginX = 7;

  // label
  NSColor *fontColor;
  NSColor *shadowColor = [NSColor colorWithDeviceWhite:1 alpha:1];
  CGSize shadowOffset = NSMakeSize(0, -1);
  if(view.selected)
  {
    fontColor = [NSColor colorWithDeviceRed:0.1255 green:0.5137 blue:0.9686 alpha:1.0000];
  }
  else if(view.online)
  {
    fontColor = [NSColor colorWithDeviceRed:0.2000 green:0.2000 blue:0.2000 alpha:1.0000];
  }
  else
  {
    fontColor = [NSColor colorWithDeviceRed:0.6078 green:0.6510 blue:0.7059 alpha:1.0000];
  }
  
  CGSize size = MVSizeOfString(view.name, 11, kMVStringTypeBold);
  CGRect stringRect = CGRectMake(marginX, 1, bounds.size.width - marginX - 2, 19);

  if(stringRect.size.width - 3 < size.width)
  {
    // mask
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CGContextRef maskContext =
    CGBitmapContextCreate(NULL,
                          bounds.size.width,
                          bounds.size.height,
                          8,
                          bounds.size.width,
                          colorspace,
                          0);
    CGColorSpaceRelease(colorspace);
    
    NSGraphicsContext *maskGraphicsContext =
    [NSGraphicsContext graphicsContextWithGraphicsPort:maskContext flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:maskGraphicsContext];
    
    [[NSColor whiteColor] set];
    CGContextFillRect(maskContext, rect);
    
    NSColor *startColor = [NSColor colorWithDeviceWhite:0 alpha:1];
    NSColor *endColor = [NSColor colorWithDeviceWhite:0 alpha:0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:CGRectMake(bounds.size.width - 8, 0,
                                    4, bounds.size.height) angle:180];
    [[NSColor blackColor] set];
    CGContextFillRect(maskContext, CGRectMake(bounds.size.width - 4, 0, 4, bounds.size.height));
    
    [NSGraphicsContext restoreGraphicsState];
    CGImageRef alphaMask = CGBitmapContextCreateImage(maskContext);
    
    
    // use mask
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, bounds, alphaMask);
  }
  
  // draw text
  int fontStyle = view.isSelected ? kMVStringTypeMedium : kMVStringTypeNormal;
  if(view.isSelected)
    stringRect.origin.y = stringRect.origin.y + 2;
  MVDrawStringAlignLineBreakMode(view.name, stringRect, fontColor, 11, fontStyle,
                                 shadowColor, shadowOffset, 1,
                                 0,
                                 NSLineBreakByClipping);
  
  if(stringRect.size.width < size.width)
    CGContextRestoreGState(ctx);

  [[NSGraphicsContext currentContext] restoreGraphicsState];
};

@implementation MVTabView

@synthesize name            = name_,
            identifier      = identifier,
            sortable        = sortable_,
            showed          = showed_,
            selected        = selected_,
            sorting         = sorting_,
            glowing         = glowing_,
            online          = online_,
            nextTab         = nextTab_,
            previousTab     = previousTab_,
            glowingView     = glowingView_,
            mouseDown       = mouseDown_,
            mouseDragged    = mouseDragged_,
            delegate        = delegate_,
            highlighted     = highlighted_,
            sortingBackground = sortingBackground_;

#pragma mark -
#pragma mark Public Methods

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];
    self.shouldDisplayWhenWindowChangesFocus = YES;
    highlighted_ = NO;
    sorting_ = NO;
    glowing_ = NO;
    online_ = NO;
    nextTab_ = nil;
    previousTab_ = nil;
    mouseDown_ = NO;
    mouseDragged_ = NO;

    glowingView_ = [[TUIView alloc] initWithFrame:CGRectZero];
    glowingView_.userInteractionEnabled = NO;
    glowingView_.opaque = NO;
    glowingView_.backgroundColor = [TUIColor clearColor];
    glowingView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      MVTabDraw((MVTabView*)(view.superview), rect, YES, 1);
    };
    glowingView_.layout = ^(TUIView *view)
    {
      return view.superview.bounds;
    };

    sortingBackground_ = nil;

    [self addObserver:self forKeyPath:@"previousTab" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"previousTab.selected" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"previousTab.glowing" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"previousTab"];
  [self removeObserver:self forKeyPath:@"previousTab.selected"];
  [self removeObserver:self forKeyPath:@"previousTab.glowing"];
}

- (float)expectedWidth
{
  CGSize size = MVSizeOfString(self.name, 11, kMVStringTypeBold);
  float width = ceil(size.width) + 5 + 5 + 1 + 1 + 2;
  return width;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if(object == self)
    [self setNeedsDisplay];
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark Properties

- (void)setSorting:(BOOL)sorting
{
  if(sorting == sorting_)
     return;
  sorting_ = sorting;

  if(sorting_) {
    CGRect rect = CGRectMake(-5, 0, self.frame.size.width + 9, self.frame.size.height);
    if(!self.sortingBackground) {
      self.sortingBackground = [[TUIView alloc] initWithFrame:rect];
      self.sortingBackground.userInteractionEnabled = NO;
      self.sortingBackground.opaque = NO;
      self.sortingBackground.backgroundColor = [TUIColor clearColor];
      self.sortingBackground.drawRect = ^(TUIView *view, CGRect rect) {
        NSColor *startColor;
        NSColor *endColor;
        NSGradient *gradient;

        // left & right shadow
        startColor = [NSColor colorWithDeviceWhite:0 alpha:0.10];
        endColor = [NSColor colorWithDeviceWhite:0 alpha:0.0];
        gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
        [gradient drawInRect:CGRectMake(0, 1,
                                        5, view.bounds.size.height) angle:180];
        [gradient drawInRect:CGRectMake(view.bounds.size.width - 5, 1,
                                        5, view.bounds.size.height) angle:0];
      };
      self.sortingBackground.layer.opacity = 0.0;
      [self addSubview:self.sortingBackground];
    }
    else {
      [self.sortingBackground setFrame:rect];
    }

    [TUIView animateWithDuration:0.2 animations:^{
      self.sortingBackground.layer.opacity = 1.0;
    }];
  }
  else {
    if(self.sortingBackground) {
      [TUIView animateWithDuration:0.2 animations:^{
        self.sortingBackground.layer.opacity = 0.0;
      }];
      [self mv_performBlock:^{
        [self.sortingBackground removeFromSuperview];
        self.sortingBackground = nil;
      } afterDelay:0.2];
    }
  }
  [self setNeedsDisplay];
}

- (void)setGlowing:(BOOL)glowing
{
  if(glowing == glowing_)
    return;
  glowing_ = glowing;
  [self updateGlowingAnimation];
}

- (void)setSelected:(BOOL)selected
{
  if(selected == selected_)
    return;
  selected_ = selected;
  [self updateGlowingAnimation];
}

- (void)setOnline:(BOOL)online
{
  if(online == online_)
    return;
  online_ = online;
}

- (void)setNextTab:(MVTabView *)nextTab
{
  if(nextTab == nextTab_)
    return;
  nextTab_ = nextTab;
  [self setNeedsDisplay];
}

- (void)setPreviousTab:(MVTabView *)previousTab
{
  if(previousTab == previousTab_)
    return;
  previousTab_ = previousTab;
  [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)theEvent
{
  [super mouseDown:theEvent];

  self.mouseDown = YES;
  [TUIView setAnimationsEnabled:NO block:^{
    [self updateGlowingAnimation];
  }];

  [self.delegate tabViewShouldBeSelect:self];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  [super mouseDragged:theEvent];

  self.mouseDragged = YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
  [super mouseUp:theEvent];

  self.mouseDragged = NO;
  self.mouseDown = NO;
  [TUIView setAnimationsEnabled:NO block:^{
    [self updateGlowingAnimation];
  }];
}

- (BOOL)avoidDisplayWhenWindowChangesFocus
{
  return !self.isSelected;
}

#pragma mark -
#pragma mark Drawing Methods

- (void)drawRect:(CGRect)rect
{
  MVTabDraw(self, rect, NO, 0);
}

#pragma mark -
#pragma mark Private Methods

- (void)updateGlowingAnimation
{
  if(self.isGlowing && !self.isSelected && !self.mouseDown)
  {
    if(!self.glowingView.superview)
      [self addSubview:self.glowingView];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.values = [NSArray arrayWithObjects:
                        [NSNumber numberWithFloat:0.0],
                        [NSNumber numberWithFloat:1.0],
                        [NSNumber numberWithFloat:0.0],
                        nil];
    animation.repeatCount = INT_MAX;
    animation.duration = 1;
    [self.glowingView.layer addAnimation:animation
                                  forKey:@"opacity"];
  }
  else
  {
    [self.glowingView removeFromSuperview];
    [self.glowingView removeAllAnimations];
  }
  [TUIView animateWithDuration:0.5 animations:^{
    [self redraw];
  }];
}

@end
