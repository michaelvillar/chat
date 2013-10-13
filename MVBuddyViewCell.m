#import "MVBuddyViewCell.h"
#import "MVGraphicsFunctions.h"
#import "PocketSVG.h"
#import "TUIView+Easing.h"

@interface MVBuddyViewCell ()

@property (strong, readwrite) TUIView *avatarView;
@property (strong, readwrite) TUIView *labelView;
@property (strong, readwrite) TUIView *arrowView;
@property (strong, readwrite) TUIView *drawView;

@end

@implementation MVBuddyViewCell

@synthesize email = email_,
            fullname = fullname_,
            online = online_,
            avatar = avatar_,
            alternate = alternate_,
            firstRow = firstRow_,
            lastRow = lastRow_,
            representedObject = representedObject_;

@synthesize avatarView = avatarView_,
            labelView = labelView_,
            arrowView = arrowView_,
            drawView = drawView_;

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if(self)
  {
    email_ = @"";
    fullname_ = @"";
    online_ = NO;
    avatar_ = nil;
    alternate_ = NO;
    firstRow_ = NO;
    lastRow_ = NO;
    representedObject_ = nil;
    
    self.opaque = NO;
    self.backgroundColor = [TUIColor whiteColor];
    self.clipsToBounds = NO;
    
    __weak __block MVBuddyViewCell *weakSelf = self;
    avatarView_ = [[TUIView alloc] initWithFrame:CGRectMake(7.5, 4, 22, 22)];
    avatarView_.backgroundColor = [TUIColor clearColor];
    avatarView_.userInteractionEnabled = NO;
    avatarView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      [[NSGraphicsContext currentContext] saveGraphicsState];
      NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:view.bounds];
      [path addClip];
      if(weakSelf.avatar)
        [weakSelf.avatar drawInRect:view.bounds];
      [[NSGraphicsContext currentContext] restoreGraphicsState];
    };
    
    labelView_ = [[TUIView alloc] initWithFrame:CGRectZero];
    labelView_.backgroundColor = [TUIColor whiteColor];
    labelView_.userInteractionEnabled = NO;
    labelView_.drawRect =^(TUIView *view, CGRect rect)
    {
      [[NSGraphicsContext currentContext] saveGraphicsState];
      
      [[TUIColor whiteColor] set];
      [NSBezierPath fillRect:view.bounds];
      
      NSColor *fontColor;
      if(weakSelf.isOnline)
        fontColor = [NSColor colorWithDeviceWhite:0.2 alpha:1];
      else
        fontColor = [NSColor colorWithDeviceRed:0.6078 green:0.6510 blue:0.7059 alpha:1];
      MVHelDrawString(weakSelf.fullname ? weakSelf.fullname : weakSelf.email,
                      view.bounds,
                      fontColor,
                      13, NO,
                      nil, CGSizeMake(0, 0), 0);
      [[NSGraphicsContext currentContext] restoreGraphicsState];
    };
    
    arrowView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 24, 30.5)];
    arrowView_.userInteractionEnabled = NO;
    arrowView_.layout = ^(TUIView *view)
    {
      CGRect arrowViewFrame = view.frame;
      arrowViewFrame.origin.x = weakSelf.bounds.size.width - arrowViewFrame.size.width + 1;
      return arrowViewFrame;
    };
    arrowView_.backgroundColor = [TUIColor colorWithRed:0.1255 green:0.5137 blue:0.9686 alpha:1];
    arrowView_.layer.anchorPoint = CGPointMake(1, 0.5);
    arrowView_.layer.transform = CATransform3DMakeScale(0.01, 1, 1);
    
    PocketSVG *arrowSvg = [[PocketSVG alloc] initFromSVGFileNamed:@"arrow"];
    CAShapeLayer *arrowLayer = [CAShapeLayer layer];
    arrowLayer.frame = CGRectMake(8, 58, 6, 10);
    arrowLayer.path = [PocketSVG getCGPathFromNSBezierPath:arrowSvg.bezier];
    arrowLayer.fillColor = CGColorCreateGenericRGB(1, 1, 1, 1);
    arrowLayer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5);
    [arrowView_.layer addSublayer:arrowLayer];
    
    CGRect rect = self.bounds;
    rect.size.height = 30;
    drawView_ = [[TUIView alloc] initWithFrame:rect];
    drawView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    drawView_.opaque = NO;
    drawView_.backgroundColor = [TUIColor clearColor];
    drawView_.userInteractionEnabled = NO;
    drawView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      [[NSGraphicsContext currentContext] saveGraphicsState];

      [[NSColor colorWithDeviceRed:0.8314 green:0.8510 blue:0.8745 alpha:1.0000] set];
      [NSBezierPath fillRect:CGRectMake(35, 0, view.bounds.size.width - 35, 0.5)];
      
      [[NSGraphicsContext currentContext] restoreGraphicsState];
    };
    
    [self addSubview:drawView_];
    [self addSubview:labelView_];
    [self addSubview:arrowView_];
    [self addSubview:avatarView_];
  }
  return self;
}

- (void)setNeedsDisplay
{
  [self.avatarView setNeedsDisplay];
  [self.labelView setNeedsDisplay];
  [self.drawView setNeedsDisplay];
}

- (void)redraw
{
  [self.drawView redraw];
}

- (void)drawRect:(CGRect)rect
{
}

- (void)layoutSubviews
{
  float x = 36;
  if (self.isSelected)
    x = 38.5;
  self.labelView.frame = CGRectMake(x, 6.5, self.bounds.size.width - x - 10, 20);
  
  [super layoutSubviews];
}

- (void)setSelected:(BOOL)s animated:(BOOL)animated
{
  [super setSelected:s animated:animated];
  
  float duration = (s ? 0.45 : 0.2);
  [TUIView animateWithDuration:duration animations:^{
    if(s) {
      [TUIView setEasing:[CAMediaTimingFunction functionWithControlPoints:0.2 :2.5 :0.6 :1]];
      self.avatarView.layer.transform = CATransform3DMakeScale(1.1818, 1.1818, 1.1818);
    }
    else {
      [TUIView setAnimationCurve:TUIViewAnimationCurveEaseOut];
      self.avatarView.layer.transform = CATransform3DIdentity;
    }
  }];

  [TUIView animateWithDuration:duration animations:^{
    if(s) {
      [TUIView setEasing:[CAMediaTimingFunction functionWithControlPoints:0.28 :1.63 :0.46 :1]];
      self.arrowView.layer.transform = CATransform3DMakeScale(1, 1, 1);
    }
    else {
      [TUIView setAnimationCurve:TUIViewAnimationCurveEaseOut];
      self.arrowView.layer.transform = CATransform3DMakeScale(0.01, 1, 1);
    }
    [self layoutSubviews];
  }];
}

@end