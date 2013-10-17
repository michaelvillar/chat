#import "MVDiscussionMessageView.h"
#import "MVDiscussionMessageItem.h"
#import "MVDiscussionView.h"
#import "MVCircleLoaderView.h"
#import "MVAnimatedGIFView.h"
#import "MVGraphicsFunctions.h"
#import "NSBezierPath+CGPath.h"
#import "MVURLKit.h"
#import "NSObject+PerformBlockAfterDelay.h"
#import "MVShadow.h"

#define kMVDiscussionMessageViewBubbleRadius 11.5
#define kMVDiscussionMessageViewBubbleMarginLeft 9
#define kMVDiscussionMessageViewBubbleMarginRight 45
#define kMVDiscussionMessageViewTextMarginLeft 8
#define kMVDiscussionMessageViewTextMarginRight 8

#define kMVDiscussionMessageViewImageMargins 7
#define kMVDiscussionMessageViewImageRadius kMVDiscussionMessageViewBubbleRadius - 3.8

#define kMVDiscussionMessageViewNotificationMarginTop 6
#define kMVDiscussionMessageViewNotificationMarginBottom 5
#define kMVDiscussionMessageViewNotificationHeight 41
#define kMVDiscussionMessageViewNotificationSmallHeight 26

static NSGradient *ownWhiteCurveGradient;
static NSGradient *whiteCurveGradient;
static NSMutableDictionary *ownMentionGradients;
static NSMutableDictionary *bubbleGradients;
static NSMutableDictionary *ownBubbleGradients;
static NSColor *linkColor;
static NSColor *activeLinkColor;

@interface MVDiscussionMessageItem ()

@property (readwrite) CGSize cachedSize;
@property (readwrite) float cacheConstrainedToWidth;

@end

@interface MVDiscussionMessageView ()

@property (strong, readwrite) TUITextRenderer *textRenderer;
@property (strong, readwrite) NSDateFormatter *fullDateFormatter;
@property (strong, readwrite) NSDateFormatter *shortDateFormatter;
@property (strong, readwrite) NSColor *startBackgroundColor;
@property (strong, readwrite) NSColor *endBackgroundColor;
@property (strong, readwrite) NSGradient *backgroundGradient;
@property (strong, readwrite) TUIView *tooltipAvatarView;
@property (strong, readwrite) MVCircleLoaderView *loaderView;
@property (readwrite) BOOL loaderViewShouldBeVisible;
@property (readwrite, getter = isHighlighted) BOOL highlighted;
@property (strong, readwrite) TUIButton *videoPlayButton;
@property (strong, readwrite) TUIButton *serviceIconButton;
@property (strong, readwrite) TUIButton *errorButton;
@property (strong, readwrite) MVAnimatedGIFView *animatedGIFView;

- (CGRect)avatarRect;
- (void)setLoaderVisible:(BOOL)isVisible
              percentage:(float)percentage
                animated:(BOOL)animated;
- (void)updateLoader:(BOOL)animated;
- (void)updateErrorButton;
- (void)createServiceIconButton;
- (void)updateServiceIconButton;
- (void)updateVideoPlayButton;
- (void)saveFile:(NSURL*)localFileURL
       toFileURL:(NSURL*)destinationURL;
- (void)createAnimatedGIFView;

@end

#pragma mark -
#pragma mark Graphic Functions
void MVDiscussionMessageViewDrawText(MVDiscussionMessageView *view);
void MVDiscussionMessageViewDrawBubble(MVDiscussionMessageView *view);
CGRect MVDiscussionMessageViewBubbleRect(MVDiscussionMessageView *view);

CGRect MVDiscussionMessageViewBubbleRect(MVDiscussionMessageView *view)
{
  CGSize size = [[view class] sizeForItem:view.item
                       constrainedToWidth:view.bounds.size.width
                             textRenderer:view.textRenderer
                                 inWindow:view.nsWindow];
  CGRect rrect = CGRectMake(kMVDiscussionMessageViewBubbleMarginLeft, 0,
                            size.width -
                            kMVDiscussionMessageViewBubbleMarginRight -
                            kMVDiscussionMessageViewBubbleMarginLeft,
                            view.bounds.size.height);
  if(view.item.own)
    rrect.origin.x = view.bounds.size.width -
    rrect.size.width -
    kMVDiscussionMessageViewBubbleMarginLeft;
  return rrect;
}

void MVDiscussionMessageViewDrawText(MVDiscussionMessageView *view)
{
  CGRect rrect = MVDiscussionMessageViewBubbleRect(view);
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]
                                              initWithAttributedString:view.item.attributedMessage];
  NSRange range = NSMakeRange(0, [attributedString.string length]);
  [attributedString enumerateAttribute:NSLinkAttributeName
                               inRange:range
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop)
  {
    NSURL *url = value;
    if(url)
    {
      NSColor* color = ((view.activeLinkIndex >= range.location &&
                         view.activeLinkIndex <= range.location + range.length) ?
                         activeLinkColor : linkColor);
      [attributedString addAttribute:NSForegroundColorAttributeName
                               value:color
                               range:range];
    }
  }];
  if(view.item.selected || view.item.own)
    attributedString.color = [TUIColor whiteColor];
  view.textRenderer.attributedString = attributedString;

  float paddingTop = (view.item.type == kMVDiscussionMessageTypeTweet ? 45 : 0);
  view.textRenderer.frame = CGRectMake(rrect.origin.x + kMVDiscussionMessageViewTextMarginLeft +
                                       (view.item.type == kMVDiscussionMessageTypeFile ||
                                        view.item.type == kMVDiscussionMessageTypeRemoteFile ?
                                        16 : 0),
                                       rrect.origin.y + 1.5,
                                       rrect.size.width - kMVDiscussionMessageViewTextMarginLeft
                                       - kMVDiscussionMessageViewTextMarginRight -
                                       (view.item.type == kMVDiscussionMessageTypeFile ||
                                        view.item.type == kMVDiscussionMessageTypeRemoteFile ?
                                        16 : 0),
                                       rrect.size.height - 6 - paddingTop);
  [view.textRenderer draw];
}

void MVDiscussionMessageViewDrawBubble(MVDiscussionMessageView *view)
{
  BOOL inverted = view.item.own;

  [[NSGraphicsContext currentContext] saveGraphicsState];

  NSBezierPath *bubblePath;

  CGRect rrect = MVDiscussionMessageViewBubbleRect(view);

  CGFloat minx = CGRectGetMinX(rrect);
  CGFloat midx = CGRectGetMidX(rrect);
  CGFloat maxx = CGRectGetMaxX(rrect);
  CGFloat miny = CGRectGetMinY(rrect);
  CGFloat midy = CGRectGetMidY(rrect);
  CGFloat maxy = CGRectGetMaxY(rrect);
  float radius = kMVDiscussionMessageViewBubbleRadius;
  NSBezierPath *path = [NSBezierPath bezierPath];
  bubblePath = path;
  [path moveToPoint:CGPointMake(maxx, midy)];
  [path appendBezierPathWithArcFromPoint:CGPointMake(maxx, maxy)
                                 toPoint:CGPointMake(midx, maxy)
                                  radius:radius];
  [path appendBezierPathWithArcFromPoint:CGPointMake(minx, maxy)
                                 toPoint:CGPointMake(minx, midy)
                                  radius:radius];
  if(view.item.sameSenderAsPreviousItem && view.item.type != kMVDiscussionMessageTypeWriting)
  {
    [path appendBezierPathWithArcFromPoint:CGPointMake(minx, miny)
                                   toPoint:CGPointMake(midx, miny)
                                    radius:radius];
    [path appendBezierPathWithArcFromPoint:CGPointMake(maxx, miny)
                                   toPoint:CGPointMake(maxx, midy)
                                    radius:radius];
  }
  else if(inverted)
  {
    [path appendBezierPathWithArcFromPoint:CGPointMake(minx, miny)
                                   toPoint:CGPointMake(midx, miny)
                                    radius:radius];
    [path lineToPoint:CGPointMake(maxx-10.5, miny+0)];
    [path curveToPoint:CGPointMake(maxx-2.28, miny+2.75)
         controlPoint1:CGPointMake(maxx-7, miny+0)
         controlPoint2:CGPointMake(maxx-3.2, miny+1.4)];
    [path curveToPoint:CGPointMake(maxx+7, miny+1)
         controlPoint1:CGPointMake(maxx-1.33, miny+1.4)
         controlPoint2:CGPointMake(maxx-0, miny+1.20)];
    [path curveToPoint:CGPointMake(maxx+0, miny+10.5)
         controlPoint1:CGPointMake(maxx+3, miny+3)
         controlPoint2:CGPointMake(maxx+0, miny+8)];
  }
  else
  {
    [path lineToPoint:CGPointMake(minx+0, miny+10.5)];
    [path curveToPoint:CGPointMake(minx+-7, miny+1)
         controlPoint1:CGPointMake(minx+0, miny+8)
         controlPoint2:CGPointMake(minx+-3, miny+3)];
    [path curveToPoint:CGPointMake(minx+2.28, miny+2.75)
         controlPoint1:CGPointMake(minx+0, miny+1.20)
         controlPoint2:CGPointMake(minx+1.33, miny+1.4)];
    [path curveToPoint:CGPointMake(minx+10.5, miny+0)
         controlPoint1:CGPointMake(minx+3.2, miny+1.4)
         controlPoint2:CGPointMake(minx+7, miny+0)];
    [path appendBezierPathWithArcFromPoint:CGPointMake(maxx, miny)
                                   toPoint:CGPointMake(maxx, midy)
                                    radius:radius];
  }
  [path closePath];

  
  NSColor *backgroundColor;
  if(view.isHighlighted || view.item.isSelected)
  {
    if(view.windowHasFocus && view.shouldDisplayAsFirstResponder)
    {
      backgroundColor = [NSColor redColor];
    }
    else
    {
      backgroundColor = [NSColor grayColor];
    }
  }
  else if(!view.item.own)
  {
    backgroundColor = [NSColor colorWithDeviceRed:0.9137 green:0.9333 blue:0.9569 alpha:1.0000];
  }
  else
  {
    backgroundColor = [NSColor colorWithDeviceRed:0.1529 green:0.5373 blue:0.9686 alpha:1.0000];
  }

  [backgroundColor set];
  [path fill];

  [[NSGraphicsContext currentContext] restoreGraphicsState];
  [[NSGraphicsContext currentContext] saveGraphicsState];
}

void MVDiscussionMessageViewDrawOverImage(MVDiscussionMessageView *view,
                                           BOOL transparent,
                                           CGRect rrectImage);
void MVDiscussionMessageViewDrawOverImage(MVDiscussionMessageView *view,
                                           BOOL transparent,
                                           CGRect rrectImage)
{
  if(!transparent)
  {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    float radius = kMVDiscussionMessageViewImageRadius;

    // image
    NSBezierPath *imagePath = MVRoundedRectBezierPath(rrectImage, radius);

    // inset black shadow
    NSBezierPath *insetBlackBordersPath = MVRoundedRectBezierPath(CGRectInset(rrectImage, 1, 1),
                                                                   radius);
    imagePath.windingRule = NSEvenOddWindingRule;
    [imagePath appendBezierPath:insetBlackBordersPath];
    [imagePath addClip];
    if(view.isHighlighted || view.item.isSelected)
      [[NSColor colorWithDeviceWhite:0.0 alpha:0.15] set];
    else
      [[NSColor colorWithDeviceWhite:0.0 alpha:0.10] set];
    [NSBezierPath fillRect:rrectImage];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];

    // white shadow
    CGRect rrectImage2 = rrectImage;
    rrectImage2.origin.y -= 1;
    NSBezierPath *deltaPath = MVRoundedRectBezierPath(rrectImage2, radius);
    deltaPath.windingRule = NSEvenOddWindingRule;
    [deltaPath appendBezierPath:MVRoundedRectBezierPath(rrectImage, radius)];
    [deltaPath addClip];
    if(view.isHighlighted || view.item.isSelected)
    {
      if(view.windowHasFocus && view.shouldDisplayAsFirstResponder)
        [[NSColor colorWithDeviceRed:0.4902 green:0.7176 blue:0.9098 alpha:0.75] set];
      else
        [[NSColor colorWithDeviceRed:0.8039 green:0.8235 blue:0.8941 alpha:0.35] set];
    }
    else if(view.item.own)
      [[NSColor colorWithDeviceWhite:1 alpha:0.4] set];
    else
      [[NSColor whiteColor] set];
    [NSBezierPath fillRect:CGRectMake(rrectImage2.origin.x, rrectImage2.origin.y,
                                      rrectImage2.size.width, rrectImage2.size.height / 2)];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];

    // white top highlight
    rrectImage2 = CGRectInset(rrectImage, 1, 1);
    CGRect rrectImage3 = rrectImage2;
    rrectImage3.origin.y -= 1;
    NSBezierPath *highlightPath = MVRoundedRectBezierPath(rrectImage2, radius);
    highlightPath.windingRule = NSEvenOddWindingRule;
    [highlightPath appendBezierPath:MVRoundedRectBezierPath(rrectImage3, radius)];
    [highlightPath addClip];
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.1] set];
    [NSBezierPath fillRect:CGRectMake(rrectImage2.origin.x,
                                      rrectImage2.origin.y + rrectImage2.size.height / 2,
                                      rrectImage2.size.width,
                                      rrectImage2.size.height)];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }
}

void MVDiscussionMessageViewDraw(MVDiscussionMessageView *view, BOOL transparent);
void MVDiscussionMessageViewDraw(MVDiscussionMessageView *view, BOOL transparent)
{
  if(!transparent)
  {
    if(view.style == kMVDiscussionViewStyleBlueGradient && !view.item.isAnimating)
    {
      if((view.item.type == kMVDiscussionMessageTypeTimestamp ||
          view.item.type == kMVDiscussionMessageTypeFullTimestamp ||
          view.item.type == kMVDiscussionMessageTypeNotification))
      {
        [[TUIColor whiteColor] set];
        [NSBezierPath fillRect:view.bounds];
      }
    }
  }

  if(view.item.type == kMVDiscussionMessageTypeText ||
     view.item.type == kMVDiscussionMessageTypeImage ||
     view.item.type == kMVDiscussionMessageTypeFile ||
     view.item.type == kMVDiscussionMessageTypeRemoteVideo ||
     view.item.type == kMVDiscussionMessageTypeRemoteImage ||
     view.item.type == kMVDiscussionMessageTypeRemoteFile ||
     view.item.type == kMVDiscussionMessageTypeTweet ||
     view.item.type == kMVDiscussionMessageTypeWriting)
  {
    if(view.drawsBubble && !transparent)
      MVDiscussionMessageViewDrawBubble(view);

    // text
    if(view.item.type == kMVDiscussionMessageTypeText && view.item.message)
    {
      MVDiscussionMessageViewDrawText(view);
    }

    // file
    else if((view.item.type == kMVDiscussionMessageTypeFile ||
             view.item.type == kMVDiscussionMessageTypeRemoteFile) &&
              view.item.asset.isExisting &&
              view.item.asset.uploadFinished)
    {
      MVDiscussionMessageViewDrawText(view);
      if(view.item.icon)
      {
        CGRect rrect = MVDiscussionMessageViewBubbleRect(view);
        [view.item.icon drawInRect:CGRectMake(round(rrect.origin.x +
                                              kMVDiscussionMessageViewTextMarginLeft - 2),
                                              round(rrect.origin.y + rrect.size.height - 16 - 2),
                                              16, 16)
                          fromRect:CGRectZero
                         operation:NSCompositeSourceOver
                          fraction:1];
      }
    }

    // image
    else if((view.item.type == kMVDiscussionMessageTypeImage ||
             view.item.type == kMVDiscussionMessageTypeRemoteVideo ||
             view.item.type == kMVDiscussionMessageTypeRemoteImage)
            && view.item.image
            && !view.item.image.isAnimated)
    {
      [[NSGraphicsContext currentContext] saveGraphicsState];

      CGRect rrect = MVDiscussionMessageViewBubbleRect(view);
      float radius = kMVDiscussionMessageViewImageRadius;

      // image
      CGRect rrectImage = CGRectInset(rrect,
                                      kMVDiscussionMessageViewImageMargins,
                                      kMVDiscussionMessageViewImageMargins);
      NSBezierPath *imagePath = MVRoundedRectBezierPath(rrectImage, radius);
      [imagePath addClip];
      [view.item.image drawInRect:rrectImage];

      [[NSGraphicsContext currentContext] restoreGraphicsState];
      MVDiscussionMessageViewDrawOverImage(view, transparent, rrectImage);
      [[NSGraphicsContext currentContext] saveGraphicsState];
    }

    // writing
    else if(view.item.type == kMVDiscussionMessageTypeWriting)
    {
      [[TUIImage imageNamed:@"icon_writing.png" cache:YES] drawAtPoint:CGPointMake(48, 12)];
    }

    // tweet
    else if(view.item.type == kMVDiscussionMessageTypeTweet
            && view.item.image)
    {
      MVDiscussionMessageViewDrawText(view);

      // draw header
      [[NSGraphicsContext currentContext] saveGraphicsState];
      CGRect rrect = MVDiscussionMessageViewBubbleRect(view);
      CGRect headerRect = CGRectMake(rrect.origin.x, rrect.origin.y + rrect.size.height - 43,
                                     rrect.size.width, 43);

      float radius = kMVDiscussionMessageViewBubbleRadius;
      NSBezierPath *bubblePath = MVRoundedRectBezierPath(rrect, radius);
      [bubblePath addClip];

      if(view.item.own)
        [[NSColor colorWithDeviceWhite:1 alpha:0.35] set];
      else
        [[NSColor whiteColor] set];
      [NSBezierPath fillRect:headerRect];

      if(view.item.own)
        [[NSColor colorWithDeviceRed:0.5843 green:0.6510 blue:0.8314 alpha:0.65] set];
      else
        [[NSColor colorWithDeviceRed:0.7333 green:0.7647 blue:0.8196 alpha:0.55] set];
      [NSBezierPath fillRect:CGRectMake(headerRect.origin.x, headerRect.origin.y - 1,
                                        headerRect.size.width, 1)];

      [[NSColor colorWithDeviceWhite:1 alpha:(view.item.own ? 0.25 : 0.7)] set];
      [NSBezierPath fillRect:CGRectMake(headerRect.origin.x, headerRect.origin.y - 2,
                                        headerRect.size.width, 1)];

      [[NSGraphicsContext currentContext] restoreGraphicsState];

      // avatar
      [[NSGraphicsContext currentContext] saveGraphicsState];
      CGRect tweetAvatarRect = CGRectMake(headerRect.origin.x + 7, headerRect.origin.y + 7,
                                          29, 29);
      NSBezierPath *tweetAvatarPath = MVRoundedRectBezierPath(tweetAvatarRect, 7);
      [tweetAvatarPath addClip];
      [view.item.image drawInRect:tweetAvatarRect];
      [[NSGraphicsContext currentContext] restoreGraphicsState];

      CGRect overTweetRect = tweetAvatarRect;
      overTweetRect.origin.y -= 1;
      overTweetRect.size.height += 1;
      [[TUIImage imageNamed:@"avatar_over_tweet.png" cache:YES] drawInRect:overTweetRect];

      // name
      MVTwitterTweetService *twitterService = (MVTwitterTweetService*)(view.item.service);
      NSColor *shadowColor = [NSColor colorWithDeviceWhite:1 alpha:0.8];
      MVDrawString(twitterService.userName,
                    CGRectMake(headerRect.origin.x + 42, headerRect.origin.y + 21,
                               headerRect.size.width - 42 - 29, 16),
                    [NSColor blackColor],
                    12, kMVStringTypeBold,
                    shadowColor, CGSizeMake(0, -1), 0);

      // screenname
      MVDrawString([NSString stringWithFormat:@"@%@",twitterService.userScreenName],
                    CGRectMake(headerRect.origin.x + 42, headerRect.origin.y + 7,
                               headerRect.size.width - 42 - 29, 16),
                    (view.item.own ?
                     [NSColor colorWithDeviceRed:0.4980 green:0.5725 blue:0.7255 alpha:1.0000] :
                     [NSColor colorWithDeviceRed:0.5490 green:0.5725 blue:0.6039 alpha:1.0000]),
                    12, kMVStringTypeNormal,
                    shadowColor, CGSizeMake(0, -1), 0);
    }
  }

  // dates
  else if(view.item.type == kMVDiscussionMessageTypeTimestamp ||
          view.item.type == kMVDiscussionMessageTypeFullTimestamp)
  {
    CGRect rrect = CGRectMake(0, 0, view.bounds.size.width, 17);
    NSDateFormatter *dateFormatter = (view.item.type == kMVDiscussionMessageTypeFullTimestamp ?
                                      view.fullDateFormatter : view.shortDateFormatter);
    NSString *string = [dateFormatter stringFromDate:view.item.date];

    NSColor *fontColor;
    NSColor *shadowColor;
    if(view.style == kMVDiscussionViewStyleTransparent)
    {
      [[NSGraphicsContext currentContext] saveGraphicsState];

      CGSize size = MVSizeOfString(string, 9, kMVStringTypeBold);
      size.width += 10;
      float roundedRectX = round((view.bounds.size.width - size.width) / 2);
      if(dateFormatter.dateStyle == NSDateFormatterNoStyle)
      {
        roundedRectX -= 14;
        size.width += 14;
      }
      NSBezierPath *roundedPath;
      NSGradient *gradient;
      NSColor *color1;
      NSColor *color2;
      CGRect roundedRect;

      roundedRect = CGRectMake(roundedRectX - 1, 1, size.width + 2, 17);
      roundedPath = MVRoundedRectBezierPath(roundedRect, 8.5);
      [[NSColor colorWithDeviceWhite:1 alpha:0.75] set];
      [roundedPath addClip];
      [NSBezierPath fillRect:CGRectMake(roundedRectX - 1, 0, size.width + 2, 8.5)];

      [[NSGraphicsContext currentContext] restoreGraphicsState];
      [[NSGraphicsContext currentContext] saveGraphicsState];

      roundedRect = CGRectMake(roundedRectX - 1, 2, size.width + 2, 17);
      roundedPath = MVRoundedRectBezierPath(roundedRect, 8.5);

      color1 = [NSColor colorWithDeviceRed:0.7216 green:0.7216 blue:0.7216 alpha:1.0000];
      color2 = [NSColor colorWithDeviceRed:0.8549 green:0.8549 blue:0.8549 alpha:1.0000];
      gradient = [[NSGradient alloc] initWithColorsAndLocations:
                  color1, 0.0,
                  color2, 1.0,
                  nil];
      [gradient drawInBezierPath:roundedPath angle:-90];

      roundedRect = CGRectMake(roundedRectX, 3, size.width, 15);
      roundedPath = MVRoundedRectBezierPath(roundedRect, 7.5);

      color1 = [NSColor colorWithDeviceRed:0.9098 green:0.9098 blue:0.9098 alpha:1.0000];
      color2 = [NSColor colorWithDeviceRed:0.9922 green:0.9922 blue:0.9922 alpha:1.0000];
      gradient = [[NSGradient alloc] initWithColorsAndLocations:
                  [NSColor colorWithDeviceRed:0.8588 green:0.8588 blue:0.8588 alpha:1.0000], 0.0,
                  color1, 0.15,
                  color1, 0.8,
                  color2, 1.0,
                  nil];
      [gradient drawInBezierPath:roundedPath angle:-90];

      [[NSGraphicsContext currentContext] restoreGraphicsState];

      fontColor = [NSColor colorWithDeviceRed:0.5020 green:0.5020 blue:0.5020 alpha:1.0000];
      shadowColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.75];
    }
    else
    {
      fontColor = [NSColor colorWithDeviceRed:0.6431 green:0.6745 blue:0.7216 alpha:1.0000];
      shadowColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.5];
    }

    MVDrawStringAlign(string,
                       rrect,
                       fontColor,
                       9,
                       kMVStringTypeBold,
                       shadowColor,
                       CGSizeMake(0, -1),
                       0,
                       1);

    if(dateFormatter.dateStyle == NSDateFormatterNoStyle)
    {
      CGSize size = MVSizeOfString(string, 9, kMVStringTypeBold);
      CGPoint point = CGPointMake(round((view.bounds.size.width - size.width) / 2 - 16), 4);
      [[TUIImage imageNamed:(view.style == kMVDiscussionViewStyleTransparent ?
                             @"icon_clock_alternate.png" :
                             @"icon_clock.png") cache:YES] drawAtPoint:point];
    }
  }

  // notifications
  else if(view.item.type == kMVDiscussionMessageTypeNotification)
  {
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [[NSGraphicsContext currentContext] saveGraphicsState];

    if((!view.isHighlighted && !view.item.isSelected) || !view.item.notificationClickable)
    {
      // two texture lines
      CGImageRef texture = [[TUIImage imageNamed:@"notification_texture.png" cache:YES] CGImage];
      CGRect rects[1];
      rects[0] = CGRectMake(5, 0,
                            view.bounds.size.width - 10, 2);
      CGContextClipToRects(ctx, rects, 1);
      CGContextDrawTiledImage(ctx, CGRectMake(0, 0, 288, 2), texture);

      [[NSGraphicsContext currentContext] restoreGraphicsState];
      [[NSGraphicsContext currentContext] saveGraphicsState];

      rects[0] = CGRectMake(5,
                            view.bounds.size.height - 2,
                            view.bounds.size.width - 10, 2);
      CGContextClipToRects(ctx, rects, 1);
      CGContextDrawTiledImage(ctx, CGRectMake(0, view.bounds.size.height - 2, 288, 2), texture);
    }
    else
    {
      [[NSColor colorWithDeviceRed:0.8510 green:0.8784 blue:0.9294 alpha:1.0000] set];
      [NSBezierPath fillRect:CGRectMake(0, 1, view.bounds.size.width, view.bounds.size.height - 1)];

      [[NSColor colorWithDeviceWhite:1 alpha:0.5] set];
      [NSBezierPath fillRect:CGRectMake(0, 0, view.bounds.size.width, 1)];

      [[NSColor colorWithDeviceRed:0.4431 green:0.4980 blue:0.5961 alpha:0.45] set];
      [NSBezierPath fillRect:CGRectMake(0, view.bounds.size.height - 1, view.bounds.size.width, 1)];

      [[NSColor colorWithDeviceRed:0.4431 green:0.4980 blue:0.5961 alpha:0.15] set];
      [NSBezierPath fillRect:CGRectMake(0, 1, view.bounds.size.width, 1)];

      [[NSColor colorWithDeviceRed:0.4431 green:0.4980 blue:0.5961 alpha:0.10] set];
      [NSBezierPath fillRect:CGRectMake(0, view.bounds.size.height - 2, view.bounds.size.width, 1)];

      static CGImageRef noisePattern = nil;
      if (noisePattern == nil) noisePattern = MVCreateNoiseImageRef(128, 128, 0.02);
      [NSGraphicsContext saveGraphicsState];
      [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
      CGRect noisePatternRect = CGRectZero;
      noisePatternRect.size = CGSizeMake(CGImageGetWidth(noisePattern),
                                         CGImageGetHeight(noisePattern));
      NSBezierPath *path = [NSBezierPath bezierPathWithRect:CGRectMake(0, 1,
                                                                       view.bounds.size.width,
                                                                       view.bounds.size.height - 1)];
      [path addClip];
      CGContextDrawTiledImage(ctx, noisePatternRect, noisePattern);
      [NSGraphicsContext restoreGraphicsState];
    }

    [[NSGraphicsContext currentContext] restoreGraphicsState];

    // text
    NSColor *fontColor;
    NSColor *shadowColor;
    if((!view.isHighlighted && !view.item.isSelected) || !view.item.notificationClickable)
    {
      fontColor = [NSColor colorWithDeviceRed:0.5490 green:0.6157 blue:0.7216 alpha:1.0000];
      shadowColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.5];
    }
    else
    {
      fontColor = [NSColor colorWithDeviceRed:0.4118 green:0.4706 blue:0.5961 alpha:1.0000];
      shadowColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.35];
    }

    CGRect textRect = CGRectMake(32,
                                 (view.bounds.size.height ==
                                  kMVDiscussionMessageViewNotificationSmallHeight ? 8 : 22),
                                 view.bounds.size.width - 32 - 18,
                                 13);

    if(view.item.attributedNotificationAction)
    {
      MVDrawAttributedStringWithColor(view.item.attributedNotificationAction,
                                       textRect,
                                       fontColor,
                                       shadowColor,
                                       CGSizeMake(0, -1),
                                       0,
                                       0);
    }

    if(view.item.notificationDescription && view.item.notificationDescription.length > 0)
    {
      textRect.origin.y -= 13;
      MVDrawString(view.item.notificationDescription,
                    textRect,
                    fontColor,
                    11,
                    kMVStringTypeNormal,
                    shadowColor,
                    CGSizeMake(0, -1),
                    0);
    }

    // icon
    TUIImage *icon = nil;
    BOOL active = (view.isHighlighted || view.item.isSelected) &&
                  view.item.notificationClickable;
    if(view.item.notificationType == kMVDiscussionNotificationTypeTaskNew)
    {
      icon = [TUIImage imageNamed:(active ?
                                   @"icon_notification_task_new_active.png" :
                                   @"icon_notification_task_new.png") cache:YES];
    }
    else if(view.item.notificationType == kMVDiscussionNotificationTypeOnlinePresence ||
            view.item.notificationType == kMVDiscussionNotificationTypeTeamJoined)
    {
      icon = [TUIImage imageNamed:(active  ?
                                   @"icon_notification_user_plus_active.png" :
                                   @"icon_notification_user_plus.png") cache:YES];
    }
    else if(view.item.notificationType == kMVDiscussionNotificationTypeOfflinePresence ||
            view.item.notificationType == kMVDiscussionNotificationTypeTeamLeft)
    {
      icon = [TUIImage imageNamed:(active ?
                                   @"icon_notification_user_min_active.png" :
                                   @"icon_notification_user_min.png") cache:YES];
    }
    else if(view.item.notificationType == kMVDiscussionNotificationTypeTaskChecked)
    {
      icon = [TUIImage imageNamed:(active ?
                                   @"icon_notification_task_checked_active.png" :
                                   @"icon_notification_task_checked.png") cache:YES];
    }
    else if(view.item.notificationType == kMVDiscussionNotificationTypeComment)
    {
      icon = [TUIImage imageNamed:(active ?
                                   @"icon_notification_comment_active.png" :
                                   @"icon_notification_comment.png") cache:YES];
    }

    if(icon)
    {
      float y = (view.bounds.size.height == kMVDiscussionMessageViewNotificationSmallHeight ?
                 7 : 15);
      [icon drawAtPoint:CGPointMake(10, y)];
    }

    if(view.item.notificationClickable)
    {
      // right arrow
      float y = (view.bounds.size.height == kMVDiscussionMessageViewNotificationSmallHeight ?
                 7 : 15);
      CGPoint arrowPoint = CGPointMake(view.bounds.size.width - 14, y);
      [[TUIImage imageNamed:(view.isHighlighted || view.item.isSelected ?
                             @"icon_notification_arrow_active.png" :
                             @"icon_notification_arrow.png") cache:YES] drawAtPoint:arrowPoint];
    }
  }
}

@implementation MVDiscussionMessageView

@synthesize discussionView                = discussionView_,
            item                          = item_,
            textRenderer                  = textRenderer_,
            fullDateFormatter             = fullDateFormatter_,
            shortDateFormatter            = shortDateFormatter_,
            startBackgroundColor          = startBackgroundColor_,
            endBackgroundColor            = endBackgroundColor_,
            backgroundGradient            = backgroundGradient_,
            tooltipAvatarView             = tooltipAvatarView_,
            loaderView                    = loaderView_,
            loaderViewShouldBeVisible     = loaderViewShouldBeVisible_,
            highlighted                   = highlighted_,
            drawsBubble                   = drawsBubble_,
            style                         = style_,
            activeLinkIndex               = activeLinkIndex_,
            videoPlayButton               = videoPlayButton_,
            serviceIconButton             = serviceIconButton_,
            errorButton                   = errorButton_,
            animatedGIFView               = animatedGIFView_,
            shouldDisplayAsFirstResponder = shouldDisplayAsFirstResponder_;

+ (void)initialize
{
  if(!ownMentionGradients)
    ownMentionGradients = [NSMutableDictionary dictionary];
  if(!bubbleGradients)
    bubbleGradients = [NSMutableDictionary dictionary];
  if(!ownBubbleGradients)
    ownBubbleGradients = [NSMutableDictionary dictionary];
  if(!linkColor)
    linkColor = [NSColor colorWithDeviceRed:0.2835 green:0.4951 blue:0.9608 alpha:1.0000];
  if(!activeLinkColor)
    activeLinkColor = [NSColor colorWithDeviceRed:0.1791 green:0.3134 blue:0.6120 alpha:1.0000];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];
    self.shouldDisplayWhenWindowChangesFocus = YES;

    discussionView_ = nil;
    item_ = nil;
    textRenderer_ = [[TUITextRenderer alloc] init];
    textRenderer_.shouldRefuseFirstResponder = YES;
    textRenderer_.view = self;
    fullDateFormatter_ = [[NSDateFormatter alloc] init];
    fullDateFormatter_.timeStyle = NSDateFormatterShortStyle;
    fullDateFormatter_.dateStyle = NSDateFormatterMediumStyle;
    shortDateFormatter_ = [[NSDateFormatter alloc] init];
    shortDateFormatter_.timeStyle = NSDateFormatterShortStyle;
    shortDateFormatter_.dateStyle = NSDateFormatterNoStyle;
    startBackgroundColor_ = nil;
    endBackgroundColor_ = nil;
    backgroundGradient_ = nil;
    tooltipAvatarView_ = [[TUIView alloc] initWithFrame:CGRectZero];
    tooltipAvatarView_.opaque = NO;
    tooltipAvatarView_.backgroundColor = [TUIColor clearColor];
    loaderView_ = nil;
    loaderViewShouldBeVisible_ = NO;
    highlighted_ = NO;
    drawsBubble_ = YES;
    style_ = kMVDiscussionViewStyleBlueGradient;
    activeLinkIndex_ = -1;
    videoPlayButton_ = nil;
    serviceIconButton_ = nil;
    errorButton_ = nil;
    animatedGIFView_ = nil;
    shouldDisplayAsFirstResponder_ = NO;
  }
  return self;
}

- (void)dealloc
{
  if(item_)
  {
    [item_ removeObserver:self forKeyPath:@"asset.uploadPercentage"];
    [item_ removeObserver:self forKeyPath:@"asset.uploadFinished"];
    [item_ removeObserver:self forKeyPath:@"asset.downloadPercentage"];
    [item_ removeObserver:self forKeyPath:@"asset.existing"];
    [item_ removeObserver:self forKeyPath:@"error"];
    [item_ removeObserver:self forKeyPath:@"avatar"];
    [item_ removeObserver:self forKeyPath:@"sameSenderAsPreviousItem"];
    [item_ removeObserver:self forKeyPath:@"image"];
  }
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
  if (self.animatedGIFView)
    [self.animatedGIFView setNeedsDisplay];
}

- (void)redraw
{
  [super redraw];
  if (self.animatedGIFView)
    [self.animatedGIFView redraw];
}

- (void)setItem:(MVDiscussionMessageItem *)item
{
  if(item == item_)
    return;
  if(self.animatedGIFView)
  {
    [self.animatedGIFView removeFromSuperview];
    self.animatedGIFView = nil;
  }
  if(item_)
  {
    [item_ removeObserver:self forKeyPath:@"asset.uploadPercentage"];
    [item_ removeObserver:self forKeyPath:@"asset.uploadFinished"];
    [item_ removeObserver:self forKeyPath:@"asset.downloadPercentage"];
    [item_ removeObserver:self forKeyPath:@"asset.existing"];
    [item_ removeObserver:self forKeyPath:@"error"];
    [item_ removeObserver:self forKeyPath:@"avatar"];
    [item_ removeObserver:self forKeyPath:@"sameSenderAsPreviousItem"];
    [item_ removeObserver:self forKeyPath:@"image"];
  }
  item_ = item;
  if(self.item.ownMention)
    self.textRenderer.selectionColor = [TUIColor colorWithWhite:1 alpha:0.85];
  else if(self.item.own)
    self.textRenderer.selectionColor = [TUIColor colorWithWhite:1 alpha:0.35];
  else
    self.textRenderer.selectionColor = nil;
  [item addObserver:self forKeyPath:@"asset.uploadPercentage" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"asset.uploadFinished" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"asset.downloadPercentage" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"asset.existing" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"error" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"avatar" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"sameSenderAsPreviousItem" options:0 context:NULL];
  [item addObserver:self forKeyPath:@"image" options:0 context:NULL];
  [self updateLoader:NO];
  [self updateServiceIconButton];
  [self updateVideoPlayButton];
  [self updateErrorButton];
  if(item.name)
  {
    if(!self.tooltipAvatarView.superview)
      [self addSubview:self.tooltipAvatarView];
    self.tooltipAvatarView.toolTip = item.name;
    [self setNeedsLayout];
  }
  else
    [self.tooltipAvatarView removeFromSuperview];
  if(item.image && item.image.isAnimated)
  {
    [self createAnimatedGIFView];
  }
}

- (CGRect)quicklookRect
{
  if(self.item.type == kMVDiscussionMessageTypeImage ||
     self.item.type == kMVDiscussionMessageTypeRemoteImage)
  {
    CGRect rrect = MVDiscussionMessageViewBubbleRect(self);
    rrect = CGRectInset(rrect,
                        kMVDiscussionMessageViewImageMargins,
                        kMVDiscussionMessageViewImageMargins);
    return rrect;
  }
  else if(self.item.type == kMVDiscussionMessageTypeFile ||
          self.item.type == kMVDiscussionMessageTypeRemoteFile)
  {
    CGRect rrect = MVDiscussionMessageViewBubbleRect(self);
    rrect = CGRectMake(rrect.origin.x + kMVDiscussionMessageViewTextMarginLeft - 2,
                       rrect.origin.y + 2,
                       16, 16);
    return rrect;
  }
  return CGRectZero;
}

- (CGRect)bubbleRect
{
  return MVDiscussionMessageViewBubbleRect(self);
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if(self.tooltipAvatarView.superview)
  {
    self.tooltipAvatarView.frame = [self avatarRect];
  }
  if(self.animatedGIFView)
  {
    CGRect rrect = MVDiscussionMessageViewBubbleRect(self);
    CGRect rrectImage = CGRectInset(rrect,
                                    kMVDiscussionMessageViewImageMargins,
                                    kMVDiscussionMessageViewImageMargins);
    rrectImage.origin.y -= 1;
    rrectImage.size.height += 1;
    self.animatedGIFView.frame = rrectImage;
  }
}

- (BOOL)avoidDisplayWhenWindowChangesFocus
{
  return !self.item.isSelected;
}

- (void)drawRect:(CGRect)rect
{
  MVDiscussionMessageViewDraw(self, NO);
}

- (void)setBackgroundStartPercent:(float)p1
                       endPercent:(float)p2
{
  if(self.item.type == kMVDiscussionMessageTypeTimestamp ||
     self.item.type == kMVDiscussionMessageTypeFullTimestamp ||
     self.item.type == kMVDiscussionMessageTypeNotification)
  {
    self.startBackgroundColor = [NSColor colorWithDeviceRed:(0.8863 + (0.9216 - 0.8863) * p1)
                                                          green:(0.9059 + (0.9373 - 0.9059) * p1)
                                                           blue:(0.9529 + (0.9686 - 0.9529) * p1)
                                                          alpha:1.0000];
    self.endBackgroundColor = [NSColor colorWithDeviceRed:(0.8863 + (0.9216 - 0.8863) * p2)
                                                        green:(0.9059 + (0.9373 - 0.9059) * p2)
                                                         blue:(0.9529 + (0.9686 - 0.9529) * p2)
                                                        alpha:1.0000];

    self.backgroundGradient = [[NSGradient alloc] initWithColorsAndLocations:
                               self.startBackgroundColor, 0.0,
                               self.endBackgroundColor, 1.0,
                               nil];
    [self setNeedsDisplay];
  }
  else
    self.backgroundGradient = nil;
}

- (void)setShouldDisplayAsFirstResponder:(BOOL)shouldDisplayAsFirstResponder
{
  if(shouldDisplayAsFirstResponder == shouldDisplayAsFirstResponder_)
    return;
  shouldDisplayAsFirstResponder_ = shouldDisplayAsFirstResponder;
  if(self.item.isSelected || self.isHighlighted)
  {
    [TUIView animateWithDuration:0.2 animations:^{
      [self redraw];
    }];
  }
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
  NSMenu *menu = nil;
  if(self.item.type == kMVDiscussionMessageTypeImage ||
     self.item.type == kMVDiscussionMessageTypeFile ||
     self.item.type == kMVDiscussionMessageTypeRemoteImage ||
     self.item.type == kMVDiscussionMessageTypeRemoteFile)
  {
    if(!menu)
      menu = [[NSMenu alloc] init];
    NSMenuItem *item;
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open File",
                                                               @"Context menu in chat")
                                      action:@selector(menuOpenFileAction:)
                               keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
    [menu addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Save File to \"Downloads\"",
                                                               @"Context menu in chat")
                                      action:@selector(menuSaveFileToDownloadsAction:)
                               keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Save File As…",
                                                               @"Context menu in chat")
                                      action:@selector(menuSaveFileAsAction:)
                               keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
  }
  if(self.item.type == kMVDiscussionMessageTypeTweet ||
     self.item.type == kMVDiscussionMessageTypeRemoteImage ||
     self.item.type == kMVDiscussionMessageTypeRemoteVideo ||
     self.item.type == kMVDiscussionMessageTypeRemoteFile)
  {
    if(!menu)
      menu = [[NSMenu alloc] init];
    NSMenuItem *item;
    if(self.item.type == kMVDiscussionMessageTypeRemoteImage ||
       self.item.type == kMVDiscussionMessageTypeRemoteFile)
    {
      [menu addItem:[NSMenuItem separatorItem]];
    }
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open URL", @"Context menu in chat")
                                      action:@selector(menuOpenURLAction:)
                               keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy URL", @"Context menu in chat")
                                      action:@selector(menuCopyURLAction:)
                               keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
  }
  return menu;
}

#pragma mark -
#pragma mark Private Methods

- (void)saveFile:(NSURL*)localFileURL
       toFileURL:(NSURL*)destinationURL
{
  NSError *error;
  BOOL result;
  if([[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path])
  {
    result = [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:&error];
  }
  result = [[NSFileManager defaultManager] copyItemAtURL:localFileURL
                                                   toURL:destinationURL
                                                   error:&error];

	if(!result)
  {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:[error localizedDescription]];
		[alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
	}
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)menuOpenFileAction:(id)sender
{
  [self.item openURL];
}

- (void)menuSaveFileToDownloadsAction:(id)sender
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	NSURL *downloadsURL = [NSURL fileURLWithPath:[paths objectAtIndex:0]];
  NSURL *destinationURL = [NSURL fileURLWithPath:
                           [downloadsURL.path stringByAppendingPathComponent:
                            self.item.asset.originalAsset.localURL.lastPathComponent]];
  [self saveFile:self.item.asset.originalAsset.localURL
       toFileURL:destinationURL];
}

- (void)menuSaveFileAsAction:(id)sender
{
  NSURL *url = [self.item.asset.originalAsset.localURL copy];
  NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.directoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
  savePanel.nameFieldStringValue = url.lastPathComponent;
  [savePanel beginSheetModalForWindow:self.nsWindow completionHandler:^(NSInteger result) {
    if(result == NSFileHandlingPanelOKButton)
    {
      [self saveFile:url
           toFileURL:savePanel.URL];
    }
  }];
}

- (void)menuOpenURLAction:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:self.item.url];
}

- (void)menuCopyURLAction:(id)sender
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  [pboard clearContents];
  [pboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
  [pboard setData:[self.item.url.description dataUsingEncoding:NSUTF8StringEncoding]
          forType:NSPasteboardTypeString];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if(object == self.item)
  {
    if([keyPath isEqualToString:@"image"]) {
      if(self.item.image && self.item.image.isAnimated)
        [self createAnimatedGIFView];
    }
    else if([keyPath isEqualToString:@"asset.uploadPercentage"] ||
       [keyPath isEqualToString:@"asset.uploadFinished"] ||
       [keyPath isEqualToString:@"asset.downloadPercentage"] ||
       [keyPath isEqualToString:@"asset.existing"])
    {
      [self updateLoader:YES];
      [self updateServiceIconButton];
      [self updateVideoPlayButton];
      if(self.item.asset.uploadFinished && self.item.asset.isExisting &&
         ([keyPath isEqualToString:@"asset.uploadFinished"] ||
          [keyPath isEqualToString:@"asset.existing"]) &&
         (self.item.type == kMVDiscussionMessageTypeFile ||
          self.item.type == kMVDiscussionMessageTypeRemoteFile))
      {
        [TUIView animateWithDuration:0.2 animations:^{
          [self redraw];
        }];
        [self setNeedsDisplay];
      }
    }
    else if([keyPath isEqualToString:@"error"])
    {
      [self updateLoader:YES];
      [self updateErrorButton];
    }
    else if([keyPath isEqualToString:@"avatar"] ||
            [keyPath isEqualToString:@"sameSenderAsPreviousItem"])
    {
      [TUIView animateWithDuration:0.2 animations:^{
        [self redraw];
      }];
    }
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark Event Handling

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
  return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint point = [self.nsView convertPoint:theEvent.locationInWindow fromView:nil];
  point = [self convertPoint:point fromView:nil];
  if(self.item.type == kMVDiscussionMessageTypeNotification ||
     (((self.item.type == kMVDiscussionMessageTypeImage ||
       self.item.type == kMVDiscussionMessageTypeFile) &&
       (self.item.asset.isExisting && self.item.asset.uploadFinished)) &&
      CGRectContainsPoint(self.bubbleRect, point)))
  {
    self.highlighted = YES;
    self.layer.zPosition += 2;
    [self setNeedsDisplay];
  }
  [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
  if(self.highlighted)
  {
    self.highlighted = NO;
    self.layer.zPosition -= 2;
    [self setNeedsDisplay];
  }
  [super mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)event
{
  if(self.item.type == kMVDiscussionMessageTypeImage ||
     self.item.type == kMVDiscussionMessageTypeFile ||
     self.item.type == kMVDiscussionMessageTypeRemoteImage ||
     self.item.type == kMVDiscussionMessageTypeRemoteFile)
  {
    TUIImage *dragImage = TUIGraphicsDrawAsImage(self.frame.size, ^{
      MVDiscussionMessageViewDraw(self, YES);
    });
    NSImage *dragNSImage = [[NSImage alloc] initWithCGImage:dragImage.CGImage size:NSZeroSize];

    CGPoint pointInView = [self convertPoint:[self.nsView convertPoint:event.locationInWindow
                                                              fromView:nil]
                                    fromView:nil];
    float x = event.locationInWindow.x - pointInView.x;
    float y = event.locationInWindow.y - pointInView.y;
    CGPoint point = CGPointMake(x, y);

    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObject:self.item.asset.originalAsset.localURL]];
    [pboard setString:[NSString stringWithFormat:@"%lu",[self.discussionView hash]]
              forType:kMVDiscussionViewMessageDraggingType];

    [self.nsView dragImage:dragNSImage
                        at:point
                    offset:CGSizeZero
                     event:event
                pasteboard:pboard
                    source:self
                 slideBack:YES];
    return;
  }

  if(!self.highlighted)
    [super mouseDragged:event];
}

#pragma mark -
#pragma mark Control Actions

- (void)videoPlayButtonAction:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:self.item.url];
}

- (void)serviceIconButtonAction:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:self.item.url];
}

- (void)errorButtonAction:(id)sender
{
  if(self.item.isFailedSentMessage)
  {
    if([self.item.delegate respondsToSelector:
        @selector(discussionMessageItemShouldRetrySendingMessage:)])
      [self.item.delegate discussionMessageItemShouldRetrySendingMessage:self.item];
  }
  else
  {
    if([self.item.delegate respondsToSelector:
        @selector(discussionMessageItemShouldRetryFileTransfer:)])
      [self.item.delegate discussionMessageItemShouldRetryFileTransfer:self.item];
  }
}

#pragma mark -
#pragma mark Classes Methods

+ (CGFloat)marginTopForItem:(MVDiscussionMessageItem*)item
{
  if(item.type == kMVDiscussionMessageTypeNotification)
  {
    if(item.previousItem.type == kMVDiscussionMessageTypeNotification)
      return - 2;
    return kMVDiscussionMessageViewNotificationMarginTop;
  }
  else
  {
    if(item.previousItem.type == kMVDiscussionMessageTypeNotification)
      return kMVDiscussionMessageViewNotificationMarginBottom;
  }
  return 3;
}

+ (CGSize)sizeForItem:(MVDiscussionMessageItem*)item
   constrainedToWidth:(float)width
         textRenderer:(TUITextRenderer*)textRenderer
             inWindow:(NSWindow*)window
{
  if(width == item.cacheConstrainedToWidth)
    return item.cachedSize;
  float w = width;
  if(((item.type == kMVDiscussionMessageTypeImage ||
       item.type == kMVDiscussionMessageTypeRemoteVideo ||
       item.type == kMVDiscussionMessageTypeRemoteImage ||
       item.type == kMVDiscussionMessageTypeRemoteFile ||
       item.type == kMVDiscussionMessageTypeTweet) &&
      (!item.asset.isExisting)) ||
      (item.type == kMVDiscussionMessageTypeFile && (!item.asset.uploadFinished ||
                                                      !item.asset.isExisting)))
  {
    item.cachedSize = CGSizeMake(114, 31);
  }
  else if((item.type == kMVDiscussionMessageTypeFile ||
           item.type == kMVDiscussionMessageTypeRemoteFile) &&
            item.asset.isExisting &&
            item.asset.uploadFinished)
  {
    if(w > 500)
      w = 500;
    float margins = kMVDiscussionMessageViewBubbleMarginLeft +
                    kMVDiscussionMessageViewBubbleMarginRight +
                    kMVDiscussionMessageViewTextMarginLeft +
                    kMVDiscussionMessageViewTextMarginRight +
                    16;
    textRenderer.attributedString = item.attributedMessage;
    CGSize size = [textRenderer sizeConstrainedToWidth:w - margins];
    item.cachedSize = CGSizeMake(MAX(114,size.width + margins), 31);
  }
  else if(item.type == kMVDiscussionMessageTypeText)
  {
    if(w > 500)
      w = 500;
    float margins = kMVDiscussionMessageViewBubbleMarginLeft +
                    kMVDiscussionMessageViewBubbleMarginRight +
                    kMVDiscussionMessageViewTextMarginLeft +
                    kMVDiscussionMessageViewTextMarginRight;
    textRenderer.attributedString = item.attributedMessage;
    CGSize size = [textRenderer sizeConstrainedToWidth:w - margins];
    item.cachedSize = CGSizeMake(size.width + margins, size.height + 9);
  }
  else if(item.type == kMVDiscussionMessageTypeTweet)
  {
    if(w > 500)
      w = 500;
    float margins = kMVDiscussionMessageViewBubbleMarginLeft +
                    kMVDiscussionMessageViewBubbleMarginRight +
                    kMVDiscussionMessageViewTextMarginLeft +
                    kMVDiscussionMessageViewTextMarginRight;
    textRenderer.attributedString = item.attributedMessage;
    CGSize size = [textRenderer sizeConstrainedToWidth:w - margins];
    float tweetWidth = size.width + margins;
    float tweetHeight = size.height + 16 + 45;

    MVTwitterTweetService *twitterService = (MVTwitterTweetService*)(item.service);
    if(twitterService)
    {
      float userNameMargins = 71 +
                              kMVDiscussionMessageViewBubbleMarginLeft +
                              kMVDiscussionMessageViewBubbleMarginRight;

      if(twitterService.userName)
      {
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                               nil];
        NSString *string = twitterService.userName;
        textRenderer.attributedString = [[NSAttributedString alloc] initWithString:string
                                                                        attributes:attrs];
        size = [textRenderer sizeConstrainedToWidth:w - userNameMargins];
        tweetWidth = MAX(tweetWidth, size.width + userNameMargins);
      }
      if(twitterService.userScreenName)
      {
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont systemFontOfSize:12], NSFontAttributeName,
                               nil];
        NSString *string = twitterService.userScreenName;
        textRenderer.attributedString = [[NSAttributedString alloc] initWithString:string
                                                                        attributes:attrs];
        size = [textRenderer sizeConstrainedToWidth:w - userNameMargins];
        tweetWidth = MAX(tweetWidth, size.width + userNameMargins);
      }
    }

    item.cachedSize = CGSizeMake(tweetWidth,
                                 tweetHeight);
  }
  else if(item.type == kMVDiscussionMessageTypeTimestamp ||
          item.type == kMVDiscussionMessageTypeFullTimestamp)
  {
    item.cachedSize = CGSizeMake(w, 22);
  }
  else if((item.type == kMVDiscussionMessageTypeImage ||
           item.type == kMVDiscussionMessageTypeRemoteVideo ||
           item.type == kMVDiscussionMessageTypeRemoteImage)
          && item.image)
  {
    if(w > 500)
      w = 500;
    float dispoHeight = 300;
    float margins = 2 * kMVDiscussionMessageViewImageMargins +
                    kMVDiscussionMessageViewBubbleMarginLeft +
                    kMVDiscussionMessageViewBubbleMarginRight;
    float dispoWidth = w - margins;
    float backingScaleFactor = (window ? window.backingScaleFactor : 1.0);
    float imageWidth = item.image.size.width / backingScaleFactor;
		float imageHeight = item.image.size.height / backingScaleFactor;
		float ratio = imageWidth / imageHeight;
    float h;
    if(dispoWidth / imageWidth > 1 && dispoHeight / imageHeight > 1)
    {
      w = imageWidth;
      h = imageHeight;
    }
    else if(dispoWidth / imageWidth < dispoHeight / imageHeight)
    {
			w = dispoWidth;
			h = w / ratio;
		}
		else
    {
      h = dispoHeight;
			w = ratio * h;
		}

    w = round(w);
		h = round(h);

    item.cachedSize = CGSizeMake(w + margins,
                                 h + 10 + 2 * kMVDiscussionMessageViewImageMargins);
  }
  else if(item.type == kMVDiscussionMessageTypeNotification)
  {
    CGSize size = CGSizeMake(width, kMVDiscussionMessageViewNotificationHeight);
    if(item.notificationType == kMVDiscussionNotificationTypeOfflinePresence ||
       item.notificationType == kMVDiscussionNotificationTypeOnlinePresence ||
       item.notificationType == kMVDiscussionNotificationTypeTeamJoined ||
       item.notificationType == kMVDiscussionNotificationTypeTeamLeft)
    {
      size.height = kMVDiscussionMessageViewNotificationSmallHeight;
    }
    item.cachedSize = size;
  }
  else if(item.type == kMVDiscussionMessageTypeWriting)
  {
    item.cachedSize = CGSizeMake(120, 31);
  }
  item.cacheConstrainedToWidth = width;
  return item.cachedSize;
}

#pragma mark -
#pragma mark Private Methods

- (CGRect)avatarRect
{
  CGRect avatarRrect = CGRectMake(6, 4, 23, 23);
  if(self.item.own)
    avatarRrect.origin.x = self.frame.size.width - 6 - 23;
  return avatarRrect;
}

- (void)setLoaderVisible:(BOOL)isVisible
              percentage:(float)percentage
                animated:(BOOL)animated
{
  self.loaderViewShouldBeVisible = isVisible;
  if(isVisible && !self.loaderView)
  {
    self.loaderView = [[MVCircleLoaderView alloc] initWithFrame:CGRectZero];
    self.loaderView.layout = ^(TUIView *view)
    {
      MVDiscussionMessageView *messageView = (MVDiscussionMessageView*)(view.superview);
      CGRect rrect = MVDiscussionMessageViewBubbleRect(messageView);
      if(messageView.item.image)
      {
        CGRect rrectImage = CGRectInset(rrect,
                                        kMVDiscussionMessageViewImageMargins,
                                        kMVDiscussionMessageViewImageMargins);

        return CGRectMake(NSMaxX(rrectImage) - 21 - 5,
                          NSMinY(rrectImage) + 5,
                          21, 21);
      }
    return CGRectMake(NSMinX(rrect) + 4, NSMinY(rrect), 21, 21);
    };
  }
  if(isVisible)
  {
    [self.loaderView removeAllAnimations];
    self.loaderView.layer.transform = CATransform3DIdentity;
    self.loaderView.layer.opacity = 1.0;
    if(self.loaderView.percentage != percentage)
    {
      self.loaderView.percentage = percentage;
      [TUIView animateWithDuration:0.1 animations:^{
        [self.loaderView redraw];
      }];
    }
    if(!self.loaderView.superview)
      [self addSubview:self.loaderView];
  }
  else
  {
    if(self.loaderView)
    {
      if(animated)
      {
        [TUIView animateWithDuration:0.2 animations:^{
          self.loaderView.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
          self.loaderView.layer.opacity = 0.0;
        }];
        [self mv_performBlock:^{
          if(!self.loaderViewShouldBeVisible)
            [self.loaderView removeFromSuperview];
        } afterDelay:0.2];
      }
      else
      {
        [self.loaderView removeFromSuperview];
      }
    }
  }
}

- (void)updateLoader:(BOOL)animated
{
  MVAsset *asset = (MVAsset*)(self.item.asset);
  if(!asset || (asset.uploadFinished && asset.isExisting) || self.item.error)
  {
    [self setLoaderVisible:NO percentage:0 animated:animated];
  }
  else
  {
    if(!asset.uploadFinished)
      [self setLoaderVisible:YES percentage:asset.uploadPercentage animated:animated];
    else
      [self setLoaderVisible:YES percentage:asset.downloadPercentage animated:animated];

    int newStyle = (asset.existing && self.item.type != kMVDiscussionMessageTypeFile &&
                    self.item.type != kMVDiscussionMessageTypeRemoteFile ?
                    kMVCircleLoaderStyleWhite :
                    (self.item.own ?
                     kMVCircleLoaderStyleEmbossedBlue : kMVCircleLoaderStyleEmbossedGrey));
    if(self.loaderView.style != newStyle)
    {
      self.loaderView.style = newStyle;
      [self.loaderView setNeedsDisplay];
    }
  }
}

- (void)updateErrorButton
{
  if(self.item.error &&
     (((self.item.type == kMVDiscussionMessageTypeFile ||
        self.item.type == kMVDiscussionMessageTypeImage) &&
        self.item.asset) ||
      (self.item.type == kMVDiscussionMessageTypeText && self.item.isFailedSentMessage)))
  {
    if(!self.errorButton)
    {
      self.errorButton = [[TUIButton alloc] initWithFrame:CGRectMake(0, 0, 17, 17)];
      [self.errorButton setImage:[TUIImage imageNamed:@"icon_error.png" cache:YES]
                        forState:TUIControlStateNormal];
      [self.errorButton setImage:[TUIImage imageNamed:@"icon_error_active.png" cache:YES]
                        forState:TUIControlStateHighlighted];
      [self.errorButton addTarget:self
                           action:@selector(errorButtonAction:)
                 forControlEvents:TUIControlEventTouchUpInside];
      self.errorButton.dimsInBackground = NO;
      self.errorButton.dimsWhenHighlighted = NO;
      self.errorButton.toolTip = NSLocalizedString(@"Transfer failed. Click to retry.",
                                                   @"Error icon button in files");

      __block __weak MVDiscussionMessageView *weakSelf = self;
      self.errorButton.layout = ^(TUIView *view)
      {
        CGRect bubbleRect = MVDiscussionMessageViewBubbleRect((MVDiscussionMessageView*)
                                                               (view.superview));
        if(weakSelf.item.isFailedSentMessage)
          return CGRectMake(bubbleRect.origin.x + bubbleRect.size.width - 9,
                            bubbleRect.origin.y + bubbleRect.size.height - 10,
                            17, 17);
        return CGRectMake(bubbleRect.origin.x + 6, 6, 17, 17);
      };
    }
    [self addSubview:self.errorButton];
  }
  else if(self.errorButton)
  {
    [self.errorButton removeFromSuperview];
  }
}

- (void)createServiceIconButton
{
  if(!self.serviceIconButton)
  {
    self.serviceIconButton = [[TUIButton alloc] initWithFrame:CGRectZero];
    self.serviceIconButton.layer.zPosition = 20;
    self.serviceIconButton.dimsInBackground = NO;
    [self.serviceIconButton addTarget:self
                               action:@selector(serviceIconButtonAction:)
                     forControlEvents:TUIControlEventTouchUpInside];
    __block __weak MVDiscussionMessageView *weakSelf = self;
    self.serviceIconButton.layout = ^(TUIView *view)
    {
      MVDiscussionMessageView *messageView = (MVDiscussionMessageView*)(view.superview);
      CGRect rrect = MVDiscussionMessageViewBubbleRect(messageView);
      if(rrect.size.width < 40 || rrect.size.height < 40)
        return CGRectZero;
      CGRect rrectImage = CGRectInset(rrect,
                                      kMVDiscussionMessageViewImageMargins,
                                      kMVDiscussionMessageViewImageMargins);
      if([weakSelf.item.service isKindOfClass:[MVYoutubeVideoService class]])
        return CGRectMake(NSMaxX(rrectImage) - 32, NSMaxY(rrectImage) - 19,
                          25, 12);
      else if([weakSelf.item.service isKindOfClass:[MVVimeoVideoService class]])
        return CGRectMake(NSMaxX(rrectImage) - 24, NSMaxY(rrectImage) - 21,
                          18, 15);
      else if([weakSelf.item.service isKindOfClass:[MVDribbbleShotService class]])
        return CGRectMake(NSMaxX(rrectImage) - 24, NSMaxY(rrectImage) - 25,
                          17, 18);
      else if([weakSelf.item.service isKindOfClass:[MVFlickrPhotoService class]])
        return CGRectMake(NSMaxX(rrectImage) - 26, NSMaxY(rrectImage) - 20,
                          19, 11);
      else if([weakSelf.item.service isKindOfClass:[MVCloudAppLinkService class]])
        return CGRectMake(NSMaxX(rrectImage) - 25, NSMaxY(rrectImage) - 22,
                          18, 14);
      else if([weakSelf.item.service isKindOfClass:[MVDroplrLinkService class]])
        return CGRectMake(NSMaxX(rrectImage) - 23, NSMaxY(rrectImage) - 25,
                          16, 17);
      else if([weakSelf.item.service isKindOfClass:[MVImageService class]])
        return CGRectMake(NSMaxX(rrectImage) - 22, NSMaxY(rrectImage) - 24,
                          15, 16);
      else if([weakSelf.item.service isKindOfClass:[MVTwitterTweetService class]])
        return CGRectMake(NSMaxX(rrect) - 26, NSMaxY(rrect) - 22,
                          17, 14);
      return CGRectZero;
    };
  }
  if(!self.serviceIconButton.superview)
    [self addSubview:self.serviceIconButton];
}

- (void)updateServiceIconButton
{
  if(self.item.asset.isExisting)
  {
    [self createServiceIconButton];
    TUIImage *icon = nil;
    self.serviceIconButton.dimsWhenHighlighted = YES;
    [self.serviceIconButton setImage:nil
                            forState:TUIControlStateHighlighted];
    if([self.item.service isKindOfClass:[MVYoutubeVideoService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_youtube.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVVimeoVideoService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_vimeo.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVDribbbleShotService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_dribbble.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVFlickrPhotoService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_flickr.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVCloudAppLinkService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_cloudapp.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVDroplrLinkService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_droplr.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVImageService class]])
    {
      icon = [TUIImage imageNamed:@"icon_service_other.png" cache:YES];
    }
    else if([self.item.service isKindOfClass:[MVTwitterTweetService class]])
    {
      if(self.item.own)
        icon = [TUIImage imageNamed:@"icon_service_twitter_own.png" cache:YES];
      else
        icon = [TUIImage imageNamed:@"icon_service_twitter.png" cache:YES];
      [self.serviceIconButton setImage:[TUIImage imageNamed:@"icon_service_twitter_active.png"
                                                      cache:YES]
                              forState:TUIControlStateHighlighted];
      self.serviceIconButton.dimsWhenHighlighted = NO;
    }
    [self.serviceIconButton setImage:icon
                            forState:TUIControlStateNormal];
    return;
  }
  if(self.serviceIconButton && self.serviceIconButton.superview)
    [self.serviceIconButton removeFromSuperview];
}

- (void)updateVideoPlayButton
{
  if(self.item.type == kMVDiscussionMessageTypeRemoteVideo &&
     self.item.asset.isExisting)
  {
    if(!self.videoPlayButton)
    {
      self.videoPlayButton = [[TUIButton alloc] initWithFrame:CGRectZero];
      self.videoPlayButton.layout = ^(TUIView *view)
      {
        MVDiscussionMessageView *messageView = (MVDiscussionMessageView*)(view.superview);
        CGRect rrect = MVDiscussionMessageViewBubbleRect(messageView);
        return CGRectMake(round(NSMidX(rrect) - 43 / 2),
                          round(NSMidY(rrect) - 40 / 2),
                          43, 40);
      };
      self.videoPlayButton.dimsInBackground = NO;
      [self.videoPlayButton setImage:[TUIImage imageNamed:@"icon_video_play.png" cache:YES]
                            forState:TUIControlStateNormal];
      [self.videoPlayButton setImage:[TUIImage imageNamed:@"icon_video_play_active.png" cache:YES]
                            forState:TUIControlStateHighlighted];
      [self.videoPlayButton addTarget:self
                               action:@selector(videoPlayButtonAction:)
                     forControlEvents:TUIControlEventTouchUpInside];
    }
    if(!self.videoPlayButton.superview)
      [self addSubview:self.videoPlayButton];
  }
  else if(self.videoPlayButton && self.videoPlayButton.superview)
  {
    [self.videoPlayButton removeFromSuperview];
  }
}

- (void)createAnimatedGIFView
{
  if (self.animatedGIFView)
    [self.animatedGIFView removeFromSuperview];
  self.animatedGIFView = [[MVAnimatedGIFView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                                             image:self.item.image
                                                   preDrawingBlock:^(TUIView *view, CGRect rect)
  {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    CGRect rrect = view.bounds;
    rrect.origin.y += 1;
    rrect.size.height -= 1;
    NSBezierPath *imagePath = MVRoundedRectBezierPath(rrect,
                                                       kMVDiscussionMessageViewImageRadius);
    [imagePath addClip];
  }
                                                  postDrawingBlock:^(TUIView *view, CGRect rect)
  {
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    CGRect rrect = view.bounds;
    rrect.origin.y += 1;
    rrect.size.height -= 1;
    MVDiscussionMessageViewDrawOverImage(self, NO, rrect);
  }];
  self.animatedGIFView.userInteractionEnabled = NO;
  [self addSubview:self.animatedGIFView];
  [self.animatedGIFView startAnimating];
  [self setNeedsLayout];
}

@end
