//
//  MVNSContentView.m
//  Chat
//
//  Created by Michaël Villar on 5/8/13.
//
//

#import "MVNSContentView.h"

@interface MVNSContentView ()

@property (readwrite) BOOL scrolled;
@property (readwrite) BOOL firstScroll;

@end

@implementation MVNSContentView

@synthesize scrolled              = scrolled_,
            firstScroll           = firstScroll_;

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if(self)
  {
    scrolled_ = NO;
    firstScroll_ = NO;
  }
  return self;
}

#pragma mark Event Handling

- (void)beginGestureWithEvent:(NSEvent *)event
{
  [super beginGestureWithEvent:event];
  self.scrolled = YES;
  self.firstScroll = YES;
}

- (void)endGestureWithEvent:(NSEvent *)event
{
  [super endGestureWithEvent:event];
  if(self.scrolled || self.firstScroll)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMVNSContentViewDidEndSwipeNotification
                                                        object:self];
  }
  self.scrolled = NO;
}

- (void)scrollWheel:(NSEvent *)event
{
  if(self.scrolled)
  {
    if(self.firstScroll && event.scrollingDeltaY != 0)
      self.scrolled = NO;
    else {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:event.scrollingDeltaX], @"deltaX",
                                nil];
      [[NSNotificationCenter defaultCenter] postNotificationName:kMVNSContentViewDidSwipeWithDeltaXNotification
                                                          object:self
                                                        userInfo:userInfo];
    }
    if(self.firstScroll && (fabs(event.scrollingDeltaX) > 3 || fabs(event.scrollingDeltaY) > 3))
      self.firstScroll = NO;
  }
  
  if(!self.scrolled || self.firstScroll)
    [super scrollWheel:event];
}

@end
