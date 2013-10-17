#import "MVWindowTitleBarView.h"
#import "MVGraphicsFunctions.h"

const CGFloat INCornerClipRadius = 4.0;
const CGFloat INButtonTopOffset = 3.0;

@interface MVWindowTitleBarView ()

@property (strong, readwrite) NSButton *closeButton;
@property (strong, readwrite) NSButton *minimizeButton;

- (NSBezierPath*)clippingPathWithRect:(NSRect)aRect cornerRadius:(CGFloat)radius;

@end

@implementation MVWindowTitleBarView

@synthesize fullscreenMode            = fullscreenMode_;

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if(self)
  {
    self.closeButton = [[NSButton alloc] initWithFrame:CGRectMake(8.5, 7, 8, 8)];
    self.closeButton.image = [NSImage imageNamed:@"close"];
    self.closeButton.imagePosition = NSImageOnly;
    [self.closeButton setBordered:NO];
    [self addSubview:self.closeButton];
    
    self.minimizeButton = [[NSButton alloc] initWithFrame:CGRectMake(24.5, 7, 8, 8)];
    self.minimizeButton.image = [NSImage imageNamed:@"minimize"];
    self.minimizeButton.imagePosition = NSImageOnly;
    [self.minimizeButton setBordered:NO];
    [self addSubview:self.minimizeButton];
  }
  return self;
}

#pragma mark Drawing Methods

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSGraphicsContext currentContext] saveGraphicsState];
  BOOL drawsAsMainWindow = ([[self window] isMainWindow] && 
                            [[NSApplication sharedApplication] isActive]);
  [[self clippingPathWithRect:self.bounds cornerRadius:INCornerClipRadius] addClip];
  
  NSColor *endingColor = [NSColor colorWithDeviceRed:0.9725 green:0.9765 blue:0.9804 alpha:1];
  NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor]
                                                       endingColor:endingColor];
  [gradient drawFromPoint:NSMakePoint(0, self.bounds.size.height)
                  toPoint:NSMakePoint(0, 0) options:0];
  
  [[NSGraphicsContext currentContext] restoreGraphicsState];
  MVDrawStringAlign(self.window.title,
                    CGRectMake(0, 2.5, self.bounds.size.width, 20),
                    [NSColor blackColor], 13, kMVStringTypeNormal, nil, CGSizeZero, 0, 1);
}

- (NSBezierPath*)clippingPathWithRect:(NSRect)aRect cornerRadius:(CGFloat)radius
{
  NSBezierPath *path = [NSBezierPath bezierPath];
	NSRect rect = NSInsetRect(aRect, radius, radius);
  NSPoint cornerPoint = NSMakePoint(NSMinX(aRect), NSMinY(aRect));
  // Create a rounded rectangle path, omitting the bottom left/right corners
  [path appendBezierPathWithPoints:&cornerPoint count:1];
  cornerPoint = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
  [path appendBezierPathWithPoints:&cornerPoint count:1];
  [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) 
                                   radius:radius 
                               startAngle:0.0 
                                 endAngle:90.0];
  [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) 
                                   radius:radius 
                               startAngle:90.0 
                                 endAngle:180.0];
  [path closePath];
  return path;
}

@end
