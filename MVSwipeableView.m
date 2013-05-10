//
//  MVSwipeableView.m
//  Chat
//
//  Created by Michaël Villar on 5/8/13.
//
//

#import "MVSwipeableView.h"
#import "MVNSContentView.h"

@interface MVSwipeableView ()

@property (strong, readwrite) TUIView *contentView;
@property (strong, readwrite) NSMutableArray *swipeableViews;
@property (strong, readwrite) TUIView *currentView;
@property (readwrite) float lastDeltaX;

- (void)slideToCurrent;
- (void)layoutSwipeableSubviews;
- (CGRect)rectForSubview:(TUIView*)view;
- (float)offsetForSubview:(TUIView*)view;

@end

@implementation MVSwipeableView

@synthesize contentView = contentView_,
            swipeableViews = swipeableViews_,
            currentView = currentView_,
            lastDeltaX = lastDeltaX_,
            delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    contentView_ = [[TUIView alloc] initWithFrame:self.bounds];
    contentView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                    TUIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView_];
    
    swipeableViews_ = [NSMutableArray array];
    currentView_ = nil;
    delegate_ = nil;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(contentViewDidEndSwipe:)
               name:kMVNSContentViewDidEndSwipeNotification object:nil];
    [nc addObserver:self selector:@selector(contentViewDidSwipeWithDeltaX:)
               name:kMVNSContentViewDidSwipeWithDeltaXNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addSwipeableSubview:(TUIView *)view
{
  if([self.swipeableViews containsObject:view])
    return;
  [self.swipeableViews addObject:view];
  if(!self.currentView)
    self.currentView = view;
  
  view.autoresizingMask = TUIViewAutoresizingNone;
  view.frame = self.bounds;
  [self layoutSubviews];
  [self.contentView addSubview:view];
}

- (void)swipeToView:(TUIView *)view
{
  self.currentView = view;
  [self slideToCurrent];
}

- (void)layoutSubviews
{
  CGRect frame = CGRectMake(self.contentView.frame.origin.x, 0,
                            (self.frame.size.width + 25) * [self.swipeableViews count],
                            self.frame.size.height);
  if([self.nsView inLiveResize])
  {
    frame.origin.x = [self offsetForSubview:self.currentView];
    self.contentView.frame = frame;
  }
  [self layoutSwipeableSubviews];
}

#pragma mark Private Methods

- (void)slideToCurrent
{
  [TUIView animateWithDuration:0.4 animations:^{
    [TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
    CGRect frame = self.contentView.frame;
    frame.origin.x = [self offsetForSubview:self.currentView];
    self.contentView.frame = frame;
  }];
}

- (void)layoutSwipeableSubviews
{
  for(TUIView *view in self.swipeableViews)
  {
    if(![self.nsWindow inLiveResize] || view == self.currentView)
    {
      view.frame = [self rectForSubview:view];
      view.hidden = NO;
    }
    else
      view.hidden = YES;
  }
}

- (CGRect)rectForSubview:(TUIView*)view
{
  int i = (int)[self.swipeableViews indexOfObject:view];
  return CGRectMake(round(i * (self.bounds.size.width + 25)),
                    0,
                    self.bounds.size.width,
                    self.bounds.size.height);
}

- (float)offsetForSubview:(TUIView*)view
{
  if(!view)
    return 0;
  return - (int)[self.swipeableViews indexOfObject:view] * (self.frame.size.width + 25);
}

#pragma mark Override

- (void)willMoveToWindow:(TUINSWindow *)newWindow
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self name:NSWindowDidEndLiveResizeNotification object:self.nsWindow];
  [nc addObserver:self selector:@selector(layoutSwipeableSubviews)
             name:NSWindowDidEndLiveResizeNotification object:newWindow];
  [super willMoveToWindow:newWindow];
}

#pragma mark MVNSContentViewDelegate Methods

- (void)contentViewDidSwipeWithDeltaX:(NSNotification *)notification
{
  NSDictionary *args = notification.userInfo;
  NSNumber *deltaXNumber = [args objectForKey:@"deltaX"];
  float delta = deltaXNumber.floatValue;
  if(delta == 0)
    return;
  
  CGRect frame = self.contentView.frame;
  float x = [self offsetForSubview:self.currentView];
  
  float ratio = 5;
  int selectedViewIndex = (int)[self.swipeableViews indexOfObject:self.currentView];
  if((selectedViewIndex == 0 && delta > 0 && frame.origin.x >= x) ||
     (selectedViewIndex == [self.swipeableViews count] - 1 && delta < 0 && frame.origin.x <= x))
  {
    ratio = 20;
  }
  
  float deltaX = delta / ratio;
  if(abs(deltaX) < 1 && ratio != 20)
    deltaX = 1 * delta / abs(delta);
  self.lastDeltaX = deltaX;
  frame.origin.x = round(frame.origin.x + deltaX);
  if(frame.origin.x < x - self.frame.size.width - 25)
  {
    frame.origin.x = x - self.frame.size.width - 25;
  }
  else if(frame.origin.x > x + self.frame.size.width + 25)
  {
    frame.origin.x = x + self.frame.size.width + 25;
  }
  
  self.contentView.frame = frame;
}

- (void)contentViewDidEndSwipe:(NSNotification *)notification
{
  if(self.swipeableViews.count == 0 || !self.currentView)
    return;
  
  // find index
  int selectedIndex = (int)[self.swipeableViews indexOfObject:self.currentView];
  float currentIndexX = [self offsetForSubview:self.currentView];
  float x = self.contentView.frame.origin.x;
  int index = selectedIndex;
  
  if(x > currentIndexX && self.lastDeltaX > 1)
  {
    selectedIndex--;
    if(selectedIndex >= 0)
      index = selectedIndex;
  }
  else if(x < currentIndexX && self.lastDeltaX < -1)
  {
    selectedIndex++;
    if(selectedIndex <= [self.swipeableViews count] - 1)
      index = selectedIndex;
  }
  
  if(self.lastDeltaX >= -1 && self.lastDeltaX <= 1)
  {
    x -= (self.frame.size.width + 25) / 2;
    int i = - x / (self.frame.size.width + 25);
    if(i < 0)
      i = 0;
    else if(i > [self.swipeableViews count] - 1)
      i = (int)[self.swipeableViews count] - 1;
    if(i > selectedIndex)
      i = selectedIndex + 1;
    else if(i < selectedIndex)
      i = selectedIndex - 1;
    index = i;
  }

  TUIView *view = [self.swipeableViews objectAtIndex:index];
  self.currentView = view;
  [self slideToCurrent];
  if([self.delegate respondsToSelector:@selector(swipeableView:didSwipeToView:)])
    [self.delegate swipeableView:self didSwipeToView:self.currentView];
}

@end
