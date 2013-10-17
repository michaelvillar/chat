#import "MVWindow.h"
#import "MVWindowTitleBarView.h"

@interface MVWindow ()

@property (strong, readwrite) MVWindowTitleBarView *titleBarView;

- (void)doInit;
- (void)layoutTitleBarView:(BOOL)isInFullscreen;
- (void)layoutTrafficLightsAndContent;
- (CGFloat)trafficLightSeparation;

@end

@implementation MVWindow

@synthesize titleBarView            = titleBarView_;

#pragma mark Constructors

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag
{
  if ((self = [super initWithContentRect:contentRect 
                               styleMask:aStyle 
                                 backing:bufferingType 
                                   defer:flag])) 
  {
    [self doInit];
  }
  return self;
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag 
                   screen:(NSScreen *)screen
{
  if ((self = [super initWithContentRect:contentRect 
                               styleMask:aStyle 
                                 backing:bufferingType 
                                   defer:flag 
                                  screen:screen])) 
  {
    [self doInit];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Overriden Methods

- (void)becomeKeyWindow
{
  [super becomeKeyWindow];
  [self.titleBarView setNeedsDisplay:YES];
}

- (void)resignKeyWindow
{
  [super resignKeyWindow];
  [self.titleBarView setNeedsDisplay:YES];
}

- (void)becomeMainWindow
{
  [super becomeMainWindow];
  [self.titleBarView setNeedsDisplay:YES];
}

- (void)resignMainWindow
{
  [super resignMainWindow];
  [self.titleBarView setNeedsDisplay:YES];
}

- (void)setContentView:(NSView *)aView
{
  [super setContentView:aView];
  [self layoutTrafficLightsAndContent];
}

#pragma mark Fullscreen support

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
  [self layoutTrafficLightsAndContent];
  [self layoutTitleBarView:YES];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
  [self layoutTrafficLightsAndContent];
  [self layoutTitleBarView:NO];
}

#pragma mark Private Methods

- (void)doInit
{
  [self setMovableByWindowBackground:YES];
  
  titleBarView_ = [[MVWindowTitleBarView alloc] initWithFrame:NSZeroRect];
  [self.titleBarView setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
  
  BOOL isInFullscreen = (([self styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask);
  [self layoutTitleBarView:isInFullscreen];
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(layoutTrafficLightsAndContent) 
             name:NSWindowDidResizeNotification object:self];
  [nc addObserver:self selector:@selector(layoutTrafficLightsAndContent) 
             name:NSWindowDidMoveNotification object:self];
  [nc addObserver:self selector:@selector(windowWillEnterFullScreen:) 
             name:NSWindowWillEnterFullScreenNotification object:nil];
  [nc addObserver:self selector:@selector(windowWillExitFullScreen:) 
             name:NSWindowWillExitFullScreenNotification object:nil];
  
  [self layoutTrafficLightsAndContent];
}

- (void)layoutTitleBarView:(BOOL)isInFullscreen;
{
  self.titleBarView.fullscreenMode = isInFullscreen;
  if(isInFullscreen)
  {
    [self.contentView addSubview:self.titleBarView];
    self.titleBarView.frame = CGRectMake(0, 
                                         ((NSView*)self.contentView).frame.size.height - 
                                         kMVTitleBarHeight, 
                                         ((NSView*)self.contentView).frame.size.width, 
                                         kMVTitleBarHeight);
  }
  else
  {
    NSView *themeFrame = [[self contentView] superview];
    NSView *firstSubview = [[themeFrame subviews] objectAtIndex:0];
    [themeFrame addSubview:self.titleBarView positioned:NSWindowBelow relativeTo:firstSubview];
    
    NSRect themeFrameRect = [themeFrame frame];
    NSRect titleFrame = NSMakeRect(0.0, NSMaxY(themeFrameRect) - kMVTitleBarHeight, 
                                   NSWidth(themeFrameRect), kMVTitleBarHeight);
    [self.titleBarView setFrame:titleFrame];
  }
  [self layoutTrafficLightsAndContent];
}

- (void)layoutTrafficLightsAndContent
{
  NSButton *close = [self standardWindowButton:NSWindowCloseButton];
  NSButton *minimize = [self standardWindowButton:NSWindowMiniaturizeButton];
  NSButton *zoom = [self standardWindowButton:NSWindowZoomButton];
  
  // Set the frame of the window buttons
  NSRect closeFrame = [close frame];
  NSRect minimizeFrame = [minimize frame];
  NSRect zoomFrame = [zoom frame];

  [close setHidden:YES];
  [minimize setHidden:YES];
  [zoom setHidden:YES];
  
  closeFrame.origin.x = closeFrame.origin.y = -99;
  minimizeFrame.origin.x = minimizeFrame.origin.y = -99;
  zoomFrame.origin.x = zoomFrame.origin.y = -99;

  [close setFrame:closeFrame];
  [minimize setFrame:minimizeFrame];
  [zoom setFrame:zoomFrame];
  
  // Reposition the content view
  NSView *contentView = [self contentView];    
  NSRect windowFrame = [self frame];
  NSRect newFrame = [contentView frame];
  CGFloat titleHeight = NSHeight(windowFrame) - NSHeight(newFrame);
  [contentView setFrame:newFrame];
  [contentView setNeedsDisplay:YES];
}

- (CGFloat)trafficLightSeparation
{
  static CGFloat trafficLightSeparation = 0.0;
  if ( !trafficLightSeparation ) {
    NSButton *close = [self standardWindowButton:NSWindowCloseButton];
    NSButton *minimize = [self standardWindowButton:NSWindowMiniaturizeButton];
    trafficLightSeparation = NSMinX(minimize.frame) - NSMinX(close.frame);
  }
  return trafficLightSeparation;    
}

@end
