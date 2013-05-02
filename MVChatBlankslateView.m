#import "MVChatBlankslateView.h"
#import "MVGraphicsFunctions.h"

@implementation MVChatBlankslateView

@synthesize label           = label_,
            drawBackground  = drawBackground_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];

    label_ = nil;
    drawBackground_ = NULL;

    [self addObserver:self forKeyPath:@"frame" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"frame"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([keyPath isEqualToString:@"frame"])
  {
    if(self.superview)
      [self setNeedsDisplay];
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)drawRect:(CGRect)rect
{
  if(self.drawBackground)
    self.drawBackground(self, rect);

  CGPoint point = CGPointMake(round((self.bounds.size.width - 80) / 2),
                              round(self.bounds.size.height - 66));
  [[TUIImage imageNamed:@"icon_blankslate_chat.png" cache:YES] drawAtPoint:point];

  if(self.label)
  {
    MVDrawStringAlignLineBreakMode(self.label,
                                    CGRectMake(0, 0, self.bounds.size.width,
                                               self.bounds.size.height - 71),
                                    [NSColor colorWithDeviceRed:0.6078 green:0.6431
                                                           blue:0.7098 alpha:1.0000],
                                    12, YES,
                                    [NSColor colorWithDeviceWhite:1 alpha:0.8],
                                    CGSizeMake(0, -1),
                                    0, 1, NSLineBreakByWordWrapping);
  }
}

@end
