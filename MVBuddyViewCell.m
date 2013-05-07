//
//  MVBuddyViewCell.m
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import "MVBuddyViewCell.h"
#import "MVGraphicsFunctions.h"

@interface MVBuddyViewCell ()

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

@synthesize drawView = drawView_;

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
    self.backgroundColor = [TUIColor clearColor];
    self.clipsToBounds = NO;
    
    __weak __block MVBuddyViewCell *weakSelf = self;
    CGRect rect = self.bounds;
    rect.size.height = 37;
    drawView_ = [[TUIView alloc] initWithFrame:rect];
    drawView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    drawView_.opaque = NO;
    drawView_.backgroundColor = [TUIColor clearColor];
    drawView_.userInteractionEnabled = NO;
    drawView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      [[NSGraphicsContext currentContext] saveGraphicsState];
      if(weakSelf.isHighlighted)
      {
        [[NSColor colorWithDeviceRed:0.7961 green:0.8196 blue:0.8706 alpha:1.0000] set];
        [NSBezierPath fillRect:view.bounds];
      }
      else if(weakSelf.isAlternate)
      {
        [[NSColor colorWithCalibratedWhite:1 alpha:0.43] set];
        [NSBezierPath fillRect:view.bounds];
      }

      if(!weakSelf.isHighlighted)
        [[NSColor colorWithDeviceRed:0.5686 green:0.6353 blue:0.7804 alpha:0.37] set];
      else
        [[NSColor colorWithDeviceRed:0.5804 green:0.6118 blue:0.6706 alpha:1.0000] set];
      [NSBezierPath fillRect:CGRectMake(0, view.bounds.size.height - 1, view.bounds.size.width, 1)];

      if(weakSelf.isHighlighted)
      {
        [NSBezierPath fillRect:CGRectMake(0, 0, view.bounds.size.width, 1)];
        
        NSColor *startColor = [NSColor colorWithDeviceRed:0.6784 green:0.7098
                                                     blue:0.7647 alpha:0.3];
        NSColor *endColor = [NSColor colorWithDeviceRed:0.6784 green:0.7098
                                                   blue:0.7647 alpha:0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor
                                                             endingColor:endColor];
        [gradient drawInRect:CGRectMake(0, view.bounds.size.height - 4,
                                        view.bounds.size.width, 4) angle:-90];
        
      }

      if(!weakSelf.isHighlighted)
      {
        [[NSColor colorWithCalibratedWhite:1 alpha:0.9] set];
        [NSBezierPath fillRect:CGRectMake(0, view.bounds.size.height - 2, view.bounds.size.width, 1)];
      }

      [[NSGraphicsContext currentContext] restoreGraphicsState];
      
      
      CGRect avatarRrect = CGRectMake(6, 7, 23, 23);
      [[NSGraphicsContext currentContext] saveGraphicsState];
      NSBezierPath *path = MVRoundedRectBezierPath(avatarRrect, 4.0);
      [path addClip];
      if(weakSelf.avatar)
        [weakSelf.avatar drawInRect:avatarRrect];
      [[NSGraphicsContext currentContext] restoreGraphicsState];
      
      [[TUIImage imageNamed:@"avatar_over.png" cache:YES] drawInRect:
       CGRectMake(avatarRrect.origin.x, avatarRrect.origin.y - 1,
                  avatarRrect.size.width, avatarRrect.size.height + 1)];
      
      CGRect labelRect = CGRectMake(35, 7, view.bounds.size.width - 30 - 30, 20);
      MVDrawString(weakSelf.fullname ? weakSelf.fullname : weakSelf.email,
                   labelRect,
                   [NSColor blackColor],
                   12, NO,
                   [NSColor whiteColor], CGSizeMake(0, -1), 0);
      
      if(weakSelf.isOnline)
      {
        CGRect iconOnlineRect = CGRectMake(view.bounds.size.width - 12 - 9, 11, 12, 12);
        [[TUIImage imageNamed:@"icon_online.png" cache:YES] drawInRect:iconOnlineRect];
      }
    };
    [self addSubview:drawView_];
  }
  return self;
}

- (void)setNeedsDisplay
{
  [self.drawView setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
}

@end
