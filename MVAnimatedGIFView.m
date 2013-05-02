#import "MVAnimatedGIFView.h"

@interface MVAnimatedGIFView ()

@property (strong, readwrite) TUIImage *image;
@property (copy, readwrite) TUIViewDrawRect preDrawingBlock;
@property (copy, readwrite) TUIViewDrawRect postDrawingBlock;
@property (strong, readwrite) NSMutableArray *imageViews;
@property (strong, readwrite) NSTimer *timer;
@property (readwrite) NSUInteger currentFrame;

- (void)constructImageViews;

@end

@implementation MVAnimatedGIFView

@synthesize image           = image_,
            preDrawingBlock = preDrawingBlock_,
            postDrawingBlock= postDrawingBlock_,
            imageViews      = imageViews_,
            timer           = timer_,
            currentFrame    = currentFrame_;

- (id)initWithFrame:(CGRect)frame
              image:(TUIImage*)image
    preDrawingBlock:(TUIViewDrawRect)preDrawingBlock
   postDrawingBlock:(TUIViewDrawRect)postDrawingBlock;

{
  self = [super initWithFrame:frame];
  if(self)
  {
    image_ = image;
    preDrawingBlock_ = preDrawingBlock;
    postDrawingBlock_ = postDrawingBlock;

    imageViews_ = [NSMutableArray array];
    timer_ = nil;
    [self constructImageViews];

    currentFrame_ = 0;
    if(self.imageViews.count != 0)
      [self addSubview:[self.imageViews objectAtIndex:currentFrame_]];
  }
  return self;
}

- (void)dealloc
{
  if (self.timer)
    [self.timer invalidate];
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
  for (TUIView *view in self.imageViews)
    [view setNeedsDisplay];
}

- (void)redraw
{
  [super redraw];
  for (TUIView *view in self.imageViews)
    [view redraw];
}

- (void)startAnimating
{
  if(self.timer)
    return;
  self.timer = [NSTimer scheduledTimerWithTimeInterval:[self.image delayAtIndex:self.currentFrame]
                                                target:self
                                              selector:@selector(animationTick)
                                              userInfo:nil
                                               repeats:NO];
}

- (void)stopAnimating
{
  if (self.timer)
    [self.timer invalidate];
  self.timer = nil;
}

#pragma mark -
#pragma mark Timer Action

- (void)animationTick
{
  while(self.subviews.count > 0)
    [[self.subviews lastObject] removeFromSuperview];
  self.currentFrame++;
  if(self.currentFrame >= self.imageViews.count)
    self.currentFrame = 0;

  if(self.imageViews.count > 0)
  {
    TUIView *imageView = [self.imageViews objectAtIndex:self.currentFrame];
    if(!CGRectEqualToRect(imageView.frame, self.bounds))
    {
      imageView.frame = self.bounds;
      [imageView setNeedsDisplay];
    }
    [self addSubview:imageView];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:[self.image delayAtIndex:self.currentFrame]
                                                  target:self
                                                selector:@selector(animationTick)
                                                userInfo:nil
                                                 repeats:NO];
  }
  else
    self.timer = nil;
}

#pragma mark -
#pragma mark Private Methods

- (void)constructImageViews
{
  NSUInteger count = self.image.animatedImageCount;
  for(NSUInteger i=0;i<count;i++)
  {
    TUIView *imageView = [[TUIView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = TUIViewAutoresizingFlexibleHeight |
                                 TUIViewAutoresizingFlexibleWidth;
    imageView.opaque = NO;
    imageView.backgroundColor = [TUIColor clearColor];

    int index = i;
    imageView.drawRect = ^(TUIView *view, CGRect rect) {
      self.preDrawingBlock(view, rect);
      [self.image drawImageAtIndex:index inRect:view.bounds];
      self.postDrawingBlock(view, rect);
    };
    [imageView setNeedsDisplay];

    [self.imageViews addObject:imageView];
  }
}

@end
