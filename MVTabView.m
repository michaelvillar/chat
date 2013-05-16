#import "MVTabView.h"
#import "MVGraphicsFunctions.h"
#import "NSObject+PerformBlockAfterDelay.h"

#define kMVTabViewGlowingDuration 0.7

@interface MVTabView ()

@property (readwrite) BOOL mouseDownOnCloseButton;
@property (readwrite, getter = isHighlighted) BOOL highlighted;
@property (strong, readwrite) TUIView *sortingBackground;
@property (strong, readwrite) TUIView *glowingView;
@property (strong, readwrite) TUIButton *closeButton;
@property (readwrite) BOOL mouseDown;
@property (readwrite) BOOL mouseDragged;
@property (readwrite) BOOL mouseOverCloseButton;

- (CGRect)rectForCloseButton;
- (void)updateGlowingAnimation;
- (void)updateCloseButton;

@end

void MVTabDraw(MVTabView *view, CGRect rect, BOOL forceGlowing, int glowingPhase);
void MVTabDraw(MVTabView *view, CGRect rect, BOOL forceGlowing, int glowingPhase)
{
  CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [[NSGraphicsContext currentContext] saveGraphicsState];

  CGRect bounds = view.bounds;

  NSColor *startColor;
  NSColor *endColor;
  NSGradient *gradient;

  if((!view.isGlowing || view.isSelected || view.isHighlighted) && !forceGlowing)
  {
    // background (top bar view)
    startColor = [NSColor colorWithDeviceRed:0.8941 green:0.8941 blue:0.9020 alpha:1.0000];
    endColor = [NSColor colorWithDeviceRed:0.9686 green:0.9686 blue:0.9765 alpha:1.0000];
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:CGRectMake(0, 1, bounds.size.width - 1, bounds.size.height - 2) angle:90];

    [[NSColor colorWithDeviceRed:0.9922 green:0.9922 blue:0.9961 alpha:1.0000] set];
    [NSBezierPath fillRect:CGRectMake(0, bounds.size.height - 1, bounds.size.width - 1, 1)];

    [[NSColor colorWithDeviceRed:0.7216 green:0.7216 blue:0.7490 alpha:1.0000] set];
    [NSBezierPath fillRect:CGRectMake(0, 0, bounds.size.width - 1, 1)];

    if(view.selected)
    {
      // selected background
      CGRect rrect = CGRectMake(1, 1, bounds.size.width - 3, bounds.size.height - 1);
      TUIImage *backgroundImage = [TUIImage imageNamed:(view.windowHasFocus ?
                                                        @"tab_active.png" :
                                                        @"tab_active_unfocused.png")
                                                 cache:YES];
      [[backgroundImage stretchableImageWithLeftCapWidth:10 topCapHeight:0] drawInRect:rrect];
    }

    if(!view.selected)
    {
      if(view.highlighted)
      {
        // top highlighted gradient
        startColor = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0.35];
        NSColor *color2 = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0.8];
        NSColor *color3 = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0.5];
        endColor = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0.25];
        gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0,
                    color2, 0.6,
                    color3, 0.85,
                    endColor, 0.95,
                    endColor, 1.0,
                    nil];
        [gradient drawInRect:CGRectMake(0, 1, bounds.size.width - 1, bounds.size.height - 1)
                       angle:-90];
      }
      else
      {
        // top gradient
        startColor = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0];
        NSColor *color2 = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0.35];
        NSColor *color3 = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0.1];
        endColor = [NSColor colorWithDeviceRed:0.6706 green:0.6784 blue:0.6980 alpha:0];
        gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0,
                    color2, 0.6,
                    color3, 0.85,
                    endColor, 0.95,
                    endColor, 1.0,
                    nil];
        [gradient drawInRect:CGRectMake(0, 1, bounds.size.width - 1, bounds.size.height - 1)
                       angle:-90];
      }
    }
  }
  else
  {
    // glowing
    startColor = [NSColor colorWithDeviceRed:0.7843 green:0.9059 blue:0.7176 alpha:1.0000];
    NSColor *color2 = [NSColor colorWithDeviceRed:0.3294 green:0.7216 blue:0.1137 alpha:1.0000];
    NSColor *color3 = [NSColor colorWithDeviceRed:0.5412 green:0.8431 blue:0.2549 alpha:1.0000];
    endColor = [NSColor colorWithDeviceRed:0.6314 green:0.8902 blue:0.3176 alpha:1.0000];
    gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0,
                color2, 0.6,
                color3, 0.85,
                endColor, 0.95,
                endColor, 1.0,
                nil];
    [gradient drawInRect:CGRectMake(0, 1, bounds.size.width - 1, bounds.size.height - 1)
                   angle:-90];

    // bottom line
    [[NSColor colorWithDeviceRed:0.2157 green:0.6392 blue:0.1529 alpha:1.0000] set];
    [NSBezierPath fillRect:CGRectMake(0, 0, view.bounds.size.width - 1, 1)];

    // top line
    [[NSColor colorWithDeviceRed:0.8353 green:0.9294 blue:0.7882 alpha:1.0000] set];
    [NSBezierPath fillRect:CGRectMake(0, view.bounds.size.height - 1,
                                      view.bounds.size.width - 1, 1)];

    if(glowingPhase == 1)
    {
      // black over
      CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
      [[NSGraphicsContext currentContext] saveGraphicsState];
      [[NSColor colorWithDeviceWhite:0 alpha:0.5] set];
      CGContextSetBlendMode(ctx, kCGBlendModeSoftLight);
      [NSBezierPath fillRect:CGRectMake(0, 1,
                                        view.bounds.size.width - 1, view.bounds.size.height - 1)];
      [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
  }

  if(!view.sorting && !view.isGlowing && !view.isSelected && !view.isHighlighted &&
     (view.previousTab && !view.previousTab.isSelected && !view.previousTab.isGlowing))
  {
    // white left line
    startColor = [NSColor colorWithDeviceWhite:1 alpha:0.70];
    endColor = [NSColor colorWithDeviceWhite:1 alpha:0];
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:CGRectMake(1, 1,
                                    1, bounds.size.height - 1) angle:-90];
  }

  if(!view.nextTab && !view.sorting && !view.isGlowing && !view.isSelected && !view.isHighlighted)
  {
    // white right line
    startColor = [NSColor colorWithDeviceWhite:1 alpha:0.80];
    endColor = [NSColor colorWithDeviceWhite:1 alpha:0.20];
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:CGRectMake(bounds.size.width - 1, 1,
                                    1, bounds.size.height - 1) angle:-90];
  }

  // left & right line
  if(view.isSelected)
  {
    startColor = [NSColor colorWithDeviceRed:0.2902 green:0.3020 blue:0.3294 alpha:0.7];
    endColor = [NSColor colorWithDeviceRed:0.2902 green:0.3020 blue:0.3294 alpha:0.3];
  }
  else
  {
    startColor = [NSColor colorWithDeviceWhite:0 alpha:(view.isGlowing ? 0.25 : 0.12)];
    endColor = [NSColor colorWithDeviceWhite:0 alpha:(view.isGlowing ? 0.25 : 0.18)];
  }
  gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
  [gradient drawInRect:CGRectMake(0, 1,
                                  1, bounds.size.height) angle:-90];
  [gradient drawInRect:CGRectMake(bounds.size.width - 2, 1,
                                  1, bounds.size.height) angle:-90];

  float marginX = 7 + (view.closable ? 14 : 0);

  // label
  NSColor *fontColor;
  NSColor *shadowColor = [NSColor colorWithDeviceWhite:1 alpha:0.5];
  CGSize shadowOffset = NSMakeSize(0, -1);
  if(view.selected && !forceGlowing)
  {
    fontColor = [NSColor whiteColor];
    shadowColor = [NSColor colorWithDeviceRed:0.2902 green:0.3020 blue:0.3294 alpha:0.6];
  }
  else if((view.isGlowing && !view.isHighlighted) || forceGlowing)
  {
    fontColor = [NSColor whiteColor];
    shadowColor = [NSColor colorWithDeviceRed:0.0745 green:0.4157 blue:0.0196 alpha:0.4];
    shadowOffset = NSMakeSize(0, 1);
  }
  else
  {
    fontColor = [NSColor colorWithDeviceRed:0.3216 green:0.3255 blue:0.3490 alpha:1.0000];
  }
  
  CGSize size = MVSizeOfString(view.name, 11, YES);
  CGRect stringRect = CGRectMake(marginX, 4, bounds.size.width - marginX - 2, 15);

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
    
    startColor = [NSColor colorWithDeviceWhite:0 alpha:1];
    endColor = [NSColor colorWithDeviceWhite:0 alpha:0];
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
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
  MVDrawStringAlignLineBreakMode(view.name, stringRect, fontColor, 11, YES,
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
            closable        = closable_,
            sortable        = sortable_,
            showed          = showed_,
            selected        = selected_,
            sorting         = sorting_,
            glowing         = glowing_,
            online          = online_,
            nextTab         = nextTab_,
            previousTab     = previousTab_,
            glowingView     = glowingView_,
            closeButton     = closeButton_,
            mouseDown       = mouseDown_,
            mouseDragged    = mouseDragged_,
            mouseOverCloseButton  = mouseOverCloseButton_,
            delegate        = delegate_,
            mouseDownOnCloseButton  = mouseDownOnCloseButton_,
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
    mouseDownOnCloseButton_ = NO;
    highlighted_ = NO;
    sorting_ = NO;
    glowing_ = NO;
    online_ = NO;
    nextTab_ = nil;
    previousTab_ = nil;
    mouseDown_ = NO;
    mouseDragged_ = NO;
    mouseOverCloseButton_ = NO;

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

    [self updateCloseButton];

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
  CGSize size = MVSizeOfString(self.name, 11, YES);
  if(self.closable)
    size.width += 14;
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
  [self updateCloseButton];
}

- (void)setSelected:(BOOL)selected
{
  if(selected == selected_)
    return;
  selected_ = selected;
  [self updateGlowingAnimation];
  [self updateCloseButton];
}

- (void)setClosable:(BOOL)closable
{
  if(closable == closable_)
    return;
  closable_ = closable;
  [self updateCloseButton];
}

- (void)setOnline:(BOOL)online
{
  if(online == online_)
    return;
  online_ = online;
  [self updateCloseButton];
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
  [self updateCloseButton];

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
  [self updateCloseButton];
}

- (void)mouseEntered:(NSEvent *)event onSubview:(TUIView *)subview
{
  if(subview == self.closeButton)
  {
    self.mouseOverCloseButton = YES;
    [self updateCloseButton];
  }
  else
    [super mouseEntered:event onSubview:subview];
}

- (void)mouseExited:(NSEvent *)event fromSubview:(TUIView *)subview
{
  if(subview == self.closeButton)
  {
    self.mouseOverCloseButton = NO;
    [self updateCloseButton];
  }
  else
    [super mouseExited:event fromSubview:subview];
}

- (BOOL)avoidDisplayWhenWindowChangesFocus
{
  return !self.isSelected;
}

#pragma mark -
#pragma mark Control Actions

- (void)closeButtonAction
{
  if(!self.isSelected)
  {
    if([self.delegate respondsToSelector:@selector(tabViewShouldBeSelect:)])
      [self.delegate tabViewShouldBeSelect:self];
  }
  else if([self.delegate respondsToSelector:@selector(tabViewShouldBeClose:)])
    [self.delegate tabViewShouldBeClose:self];
}

#pragma mark -
#pragma mark Drawing Methods

- (void)drawRect:(CGRect)rect
{
  MVTabDraw(self, rect, NO, 0);
}

#pragma mark -
#pragma mark Private Methods

- (CGRect)rectForCloseButton
{
  return CGRectMake(6, 5, 12, 12);
}

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

- (void)updateCloseButton
{
  if(self.closable)
  {
    BOOL glowing = self.isGlowing && !self.isSelected && !self.mouseDown;
    if(!self.closeButton)
    {
      self.closeButton = [[TUIButton alloc] initWithFrame:CGRectMake(6, 5, 12, 13)];
      self.closeButton.dimsInBackground = NO;
      self.closeButton.layer.zPosition = 10;
      [self.closeButton setImage:[TUIImage imageNamed:@"tab_close_active.png" cache:YES]
                        forState:TUIControlStateHighlighted];
      [self.closeButton addTarget:self
                           action:@selector(closeButtonAction)
                 forControlEvents:TUIControlEventTouchUpInside];
    }
    self.closeButton.enabled = self.isSelected;
    self.closeButton.userInteractionEnabled = self.isSelected;
    [self.closeButton setImage:[TUIImage imageNamed:(self.mouseOverCloseButton ?
                                                     (glowing ?
                                                      @"tab_close_glowing.png" :
                                                      @"tab_close.png") :
                                                     (self.isOnline ?
                                                      (glowing ?
                                                       @"tab_online_glowing.png" :
                                                       @"tab_online.png") :
                                                      (glowing ?
                                                       @"tab_offline_glowing.png" :
                                                       @"tab_offline.png")))
                                              cache:YES]
                      forState:TUIControlStateNormal];
    if(!self.closeButton.superview)
      [self addSubview:self.closeButton];
  }
  else if(self.closeButton)
  {
    [self.closeButton removeFromSuperview];
    self.closeButton = nil;
  }
}

@end
