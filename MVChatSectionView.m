#import "MVChatSectionView.h"
#import "MVDiscussionView.h"
#import "MVBottomBarView.h"
#import "MVRoundedTextView.h"
#import "MVTabsView.h"
#import "MVChatBlankslateView.h"
#import "MVActivityIndicatorView.h"
#import "NSObject+PerformBlockAfterDelay.h"

static NSGradient *backgroundGradient;

@interface MVChatSectionView () <MVRoundedTextViewDelegate,
                                  MVTabsViewDelegate,
                                  MVDiscussionViewDelegate>

@property (strong, readwrite) MVBottomBarView *bottomBarView;
@property (strong, readwrite) MVRoundedTextView *textView;
@property (strong, readwrite) TUIButton *offlineButton;
@property (strong, readwrite) MVActivityIndicatorView *connectingSpinner;
@property (strong, readwrite) MVTabsView *tabsBarView;
@property (strong, readwrite) MVDiscussionView *discussionView;
@property (strong, readwrite) MVChatBlankslateView *blankslateView;
@property (readwrite) BOOL blankslateDisplayed;

- (void)updateFromOnline;
- (void)updateBottomBarViewFrame;
- (void)updateDiscussionViewFrame;
- (void)setDiscussionViewFront:(BOOL)front;
- (void)updateBlankslateVisibility:(BOOL)animated;

@end

@implementation MVChatSectionView

@synthesize bottomBarView         = bottomBarView_,
            textView              = textView_,
            offlineButton         = offlineButton_,
            connectingSpinner     = connectingSpinner_,
            tabsBarView           = tabsBarView_,
            discussionView        = discussionView_,
            blankslateView        = blankslateView_,
            blankslateDisplayed   = blankslateDisplayed_,
            state                 = state_,
            delegate              = delegate_;

+ (void)initialize
{
  if(!backgroundGradient)
  {
    NSColor *bottomColor = [NSColor colorWithDeviceRed:0.8863
                                                 green:0.9059
                                                  blue:0.9529
                                                 alpha:1.0000];
    NSColor *topColor = [NSColor colorWithDeviceRed:0.9216
                                              green:0.9373
                                               blue:0.9686
                                              alpha:1.0000];

    backgroundGradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                       endingColor:topColor];
  }
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    discussionView_ = nil;
    textView_ = nil;
    state_ = kMVChatSectionViewStateOnline;

    bottomBarView_ = [[MVBottomBarView alloc] initWithFrame:
                                    CGRectMake(0, 0, self.frame.size.width, 30)];
    bottomBarView_.leftBottomCornerMask = YES;
    bottomBarView_.layer.zPosition = 2;
//    [self addSubview:bottomBarView_];

    offlineButton_ = [[TUIButton alloc] initWithFrame:CGRectMake(0, 7, 16, 15)];
    offlineButton_.autoresizingMask = TUIViewAutoresizingFlexibleLeftMargin |
                                      TUIViewAutoresizingFlexibleRightMargin;
    offlineButton_.dimsInBackground = NO;
    [offlineButton_ setImage:[TUIImage imageNamed:@"icon_offline.png" cache:YES]
                    forState:TUIControlStateNormal];
    [offlineButton_ setImage:[TUIImage imageNamed:@"icon_offline_active.png" cache:YES]
                    forState:TUIControlStateHighlighted];
    [offlineButton_ addTarget:self
                       action:@selector(offlineButtonAction)
             forControlEvents:TUIControlEventTouchUpInside];
    [offlineButton_ setToolTip:NSLocalizedString(@"Try to reconnect",
                                                 @"Offline button tooltip")];

    connectingSpinner_ = [[MVActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 7, 0, 0)];
    connectingSpinner_.userInteractionEnabled = NO;
    connectingSpinner_.style = kMVActivityIndicatorStyleBottomBar;
    connectingSpinner_.autoresizingMask = TUIViewAutoresizingFlexibleLeftMargin |
                                          TUIViewAutoresizingFlexibleRightMargin;

    tabsBarView_ = [[MVTabsView alloc] initWithFrame:CGRectMake(0, self.frame.size.height,
                                                                 self.frame.size.width, 23)];
    tabsBarView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                    TUIViewAutoresizingFlexibleBottomMargin;
    tabsBarView_.delegate = self;
    tabsBarView_.layer.zPosition = 10;
    [self addSubview:tabsBarView_];

    blankslateView_ = [[MVChatBlankslateView alloc] initWithFrame:CGRectMake(0, 0, 226, 130)];
    blankslateView_.label = NSLocalizedString(@"Start discussing", @"Chat blankslate label");
    blankslateView_.layer.opacity = 0.0;

    __block __weak MVChatSectionView *weakSelf = self;
    blankslateView_.drawBackground = ^(TUIView *view, CGRect rect)
    {
      float p1 = NSMinY(view.frame) / weakSelf.bounds.size.height;
      float p2 = NSMaxY(view.frame) / weakSelf.bounds.size.height;
      NSColor *startBackgroundColor = [NSColor colorWithDeviceRed:(0.8863 + (0.9216 - 0.8863) * p1)
                                                        green:(0.9059 + (0.9373 - 0.9059) * p1)
                                                         blue:(0.9529 + (0.9686 - 0.9529) * p1)
                                                        alpha:1.0000];
      NSColor *endBackgroundColor = [NSColor colorWithDeviceRed:(0.8863 + (0.9216 - 0.8863) * p2)
                                                      green:(0.9059 + (0.9373 - 0.9059) * p2)
                                                       blue:(0.9529 + (0.9686 - 0.9529) * p2)
                                                      alpha:1.0000];

      NSGradient *backgroundGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                        startBackgroundColor, 0.0,
                                        endBackgroundColor, 1.0,
                                        nil];
      [backgroundGradient drawInRect:view.bounds angle:90];
    };
    blankslateView_.layout = ^(TUIView *view)
    {
      CGRect frame = weakSelf.blankslateView.frame;
      frame.origin.x = round((weakSelf.bounds.size.width - frame.size.width) / 2);
      float height = weakSelf.bounds.size.height - weakSelf.bottomBarView.frame.size.height;
      frame.origin.y = round((height - frame.size.height) / 5 * 2.7);
      return frame;
    };
    blankslateDisplayed_ = NO;

    delegate_ = nil;
  }
  return self;
}

- (void)dealloc
{
  if(self.discussionView)
  {
    [self.discussionView removeObserver:self forKeyPath:@"countItems"];
    [self.discussionView removeObserver:self forKeyPath:@"allowsBlankslate"];
  }
}

- (void)getDiscussionView:(MVDiscussionView**)discussionView
                 textView:(MVRoundedTextView**)textView
{
  MVDiscussionView *aDiscussionView = [[MVDiscussionView alloc] initWithFrame:
                     CGRectMake(0, 30,
                                self.frame.size.width, self.frame.size.height - 30 - 23)];
  aDiscussionView.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                     TUIViewAutoresizingFlexibleHeight;
  aDiscussionView.delegate = self;

  MVRoundedTextView *aTextView = [[MVRoundedTextView alloc] initWithFrame:
                                CGRectMake(31, 0,
                                           self.bottomBarView.bounds.size.width - 63, 29)];
  aTextView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
  aTextView.delegate = self;
  aTextView.layer.zPosition = 2;
  [aTextView registerForDraggedTypes:[NSArray arrayWithObjects:
                                      NSPasteboardTypeTIFF,
                                      NSPasteboardTypePNG,
                                      NSFilenamesPboardType,
                                      nil]];

  *discussionView = aDiscussionView;
  *textView = aTextView;
}

- (void)displayDiscussionView:(MVDiscussionView*)discussionView
                     textView:(MVRoundedTextView*)textView
{
  if(discussionView != self.discussionView)
  {
    if(self.discussionView)
    {
      [self.discussionView removeObserver:self forKeyPath:@"countItems"];
      [self.discussionView removeObserver:self forKeyPath:@"allowsBlankslate"];
    }
    BOOL firstResponder = (self.nsWindow.firstResponder == self.discussionView);
    [self.discussionView removeFromSuperview];
    self.discussionView = discussionView;
    
    if(self.discussionView)
    {
      [self addSubview:self.discussionView];
      [self setDiscussionViewFront:NO];
      if(firstResponder)
        [self.nsWindow tui_makeFirstResponder:self.discussionView];
      [self.discussionView addObserver:self forKeyPath:@"countItems" options:0 context:NULL];
      [self.discussionView addObserver:self forKeyPath:@"allowsBlankslate" options:0 context:NULL];
    }
    [self updateBlankslateVisibility:NO];
  }
  if(textView != self.textView)
  {
    BOOL firstResponder = [self.textView isFirstResponder];
    [self.textView removeFromSuperview];
    self.textView = textView;
    if(self.textView)
    {
      [self addSubview:self.textView];
      if(firstResponder && !self.textView.isFirstResponder)
      {
        self.textView.animatesNextFirstResponder = NO;
        [self.nsWindow tui_makeFirstResponder:self.textView];
      }
    }
  }

  CGRect textViewFrame = self.textView.frame;
  textViewFrame.size.width = self.bottomBarView.bounds.size.width - 63;
  self.textView.frame = textViewFrame;

  [self updateFromOnline];
  [self updateBottomBarViewFrame];
}

- (void)drawRect:(CGRect)rect
{
  CGRect rrect = CGRectMake(0, 30, self.bounds.size.width, self.bounds.size.height - 30);
  [backgroundGradient drawInRect:rrect
                           angle:90];

  [[NSColor colorWithDeviceRed:0.9608 green:0.9686 blue:0.9843 alpha:1.0000] set];
  NSRectFill(CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1));
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if(!self.textView)
  {
    [self updateBottomBarViewFrame];
  }
}

- (void)forwardKeyDownEventToTextView:(NSEvent*)event
{
  if(self.textView)
  {
    [self.nsWindow tui_makeFirstResponder:self.textView];

    CGPoint location = CGPointMake(10, 5);
    location = [self.textView convertPoint:location toView:nil];
    location = [self.nsView convertPoint:location toView:nil];
    NSEvent *keyEvent = [NSEvent keyEventWithType:event.type
                                         location:location
                                    modifierFlags:event.modifierFlags
                                        timestamp:event.timestamp
                                     windowNumber:event.windowNumber
                                          context:[NSGraphicsContext currentContext]
                                       characters:event.characters
                      charactersIgnoringModifiers:event.charactersIgnoringModifiers
                                        isARepeat:event.isARepeat
                                          keyCode:event.keyCode];
    [self.nsWindow postEvent:keyEvent atStart:YES];
  }
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if(([keyPath isEqualToString:@"countItems"] ||
      [keyPath isEqualToString:@"allowsBlankslate"])
     && object == self.discussionView)
  {
    [self updateBlankslateVisibility:YES];
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark Properties

- (void)setState:(int)state
{
  if(state_ == state)
    return;
  state_ = state;
  [self updateFromOnline];
}

#pragma mark -
#pragma mark Button Actions

- (void)offlineButtonAction
{
  if([self.delegate respondsToSelector:@selector(chatSectionViewShouldTryReconnection:)])
    [self.delegate chatSectionViewShouldTryReconnection:self];
}

#pragma mark -
#pragma mark MVRoundedTextViewDelegate Methods

- (void)roundedTextViewDidResize:(MVRoundedTextView *)chatTextView
                        animated:(BOOL)animated
{
  [TUIView animateWithDuration:0.2 animations:^{
    [TUIView setAnimationsEnabled:animated];
    [self updateBottomBarViewFrame];
    [TUIView setAnimationsEnabled:YES];
  }];
}

- (void)roundedTextView:(MVRoundedTextView*)chatTextView
             sendString:(NSString*)string
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:sendString:)])
    [self.delegate chatSectionView:self sendString:string];
}

- (void)roundedTextViewMoveUp:(MVRoundedTextView*)chatTextView
{
  if(self.discussionView)
  {
    [self.nsWindow tui_makeFirstResponder:self.discussionView];
    [self.discussionView resetSelectedItem];
    [self.discussionView selectUp];
  }
}

- (void)roundedTextViewDidBecomeFirstResponder:(MVRoundedTextView *)roundedTextView
{
  if(self.discussionView)
  {
    [self.discussionView resetSelectedItem];
  }
}

- (BOOL)roundedTextView:(MVRoundedTextView *)roundedTextView
        pastePasteboard:(NSPasteboard *)pasteboard
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:pastePasteboard:)])
    return [self.delegate chatSectionView:self pastePasteboard:pasteboard];
  return NO;
}

- (BOOL)roundedTextView:(MVRoundedTextView *)roundedTextView
      didDropPasteboard:(NSPasteboard *)pboard
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:dropPasteboard:)])
    return [self.delegate chatSectionView:self dropPasteboard:pboard];
  return NO;
}

- (void)roundedTextViewTextDidChange:(MVRoundedTextView *)roundedTextView
{
  if([self.delegate respondsToSelector:@selector(chatSectionViewTextViewTextDidChange:
                                                 discussionView:)])
    [self.delegate chatSectionViewTextViewTextDidChange:self
                                         discussionView:self.discussionView];
}

#pragma mark -
#pragma mark MVTabsViewDelegate

- (void)tabsViewDidChangeTabs:(MVTabsView *)tabsView
{
  [TUIView animateWithDuration:0.4 animations:^{
    CGRect frame = self.tabsBarView.frame;
    if([self.tabsBarView countTabs] > 1)
    {
      frame.origin.y = self.frame.size.height - 23;
    }
    else
    {
      frame.origin.y = self.frame.size.height;
    }
    self.tabsBarView.frame = frame;
    [self updateDiscussionViewFrame];
  }];

  if([self.delegate respondsToSelector:@selector(chatSectionViewDidChangeTabs:)])
    [self.delegate chatSectionViewDidChangeTabs:self];
}

- (void)tabsViewDidChangeSelection:(MVTabsView*)tabsView
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:didChangeTabSelection:)])
    [self.delegate chatSectionView:self didChangeTabSelection:tabsView.selectedTab];
}

- (void)tabsViewDidChangeOrder:(MVTabsView*)tabsView
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:tabsViewDidChangeOrder:)])
    [self.delegate chatSectionView:self tabsViewDidChangeOrder:tabsView];
}

#pragma mark -
#pragma mark MVDiscussionViewDelegate

- (void)discussionView:(MVDiscussionView*)discussionView
               keyDown:(NSEvent*)event
{
  [self forwardKeyDownEventToTextView:event];
}

- (void)discussionViewShouldBeFront:(MVDiscussionView*)discussionView
{
  if(discussionView == self.discussionView)
    [self setDiscussionViewFront:YES];
}

- (void)discussionViewShouldNotBeFront:(MVDiscussionView*)discussionView
{
  if(discussionView == self.discussionView)
    [self setDiscussionViewFront:NO];
}

- (void)discussionViewShouldGiveFocusToTextField:(MVDiscussionView*)discussionView
{
  if(self.textView)
     [self.nsWindow tui_makeFirstResponder:self.textView];
}

- (void)discussionViewShouldLoadPreviousItems:(MVDiscussionView*)discussionView
{
  if([self.delegate respondsToSelector:@selector(chatSectionViewShouldLoadPreviousItems:
                                                 discussionView:)])
    [self.delegate chatSectionViewShouldLoadPreviousItems:self
                                           discussionView:discussionView];
}

- (void)discussionViewShouldLoadNextItems:(MVDiscussionView *)discussionView
{
  if([self.delegate respondsToSelector:@selector(chatSectionViewShouldLoadNextItems:
                                                 discussionView:)])
    [self.delegate chatSectionViewShouldLoadNextItems:self
                                       discussionView:discussionView];
}

- (BOOL)discussionView:(MVDiscussionView *)discussionView
     didDropPasteboard:(NSPasteboard*)pboard
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:dropPasteboard:)])
    return [self.delegate chatSectionView:self dropPasteboard:pboard];
  return NO;
}

- (void)discussionView:(MVDiscussionView *)discussionView
  didClickNotification:(MVDiscussionMessageItem*)discussionItem
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:didClickNotification:)])
    [self.delegate chatSectionView:self didClickNotification:discussionItem];
}

- (void)discussionView:(MVDiscussionView *)discussionView
shouldRetryFileTransfer:(MVDiscussionMessageItem*)discussionItem
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:shouldRetryFileTransfer:)])
    [self.delegate chatSectionView:self shouldRetryFileTransfer:discussionItem];
}

- (void)discussionView:(MVDiscussionView *)discussionView
shouldRetrySendingMessage:(MVDiscussionMessageItem*)discussionItem
{
  if([self.delegate respondsToSelector:@selector(chatSectionView:shouldRetrySendingMessage:)])
    [self.delegate chatSectionView:self shouldRetrySendingMessage:discussionItem];
}

#pragma mark -
#pragma mark TUIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(TUIScrollView *)scrollView
{
  if([self.delegate respondsToSelector:@selector(chatSectionViewDiscussionViewDidScroll:
                                                 discussionView:)])
    [self.delegate chatSectionViewDiscussionViewDidScroll:self
                                           discussionView:self.discussionView];
}

#pragma mark -
#pragma mark Private Methods

- (void)updateBlankslateVisibility:(BOOL)animated
{
  BOOL showsBlankslate = (self.discussionView.countItems == 0 &&
                          self.discussionView.allowsBlankslate);
  if(showsBlankslate != self.blankslateDisplayed)
  {
    if(showsBlankslate)
    {
      if(!self.blankslateView.superview)
      {
        [self.blankslateView setNeedsDisplay];
        [self insertSubview:self.blankslateView belowSubview:self.discussionView];
      }
      [self.blankslateView removeAllAnimations];
      [TUIView setAnimationsEnabled:animated block:^{
        [TUIView animateWithDuration:0.4 animations:^{
          self.blankslateView.layer.opacity = 1.0;
        }];
      }];
    }
    else
    {
      [self.blankslateView removeAllAnimations];
      [TUIView setAnimationsEnabled:animated block:^{
        [TUIView animateWithDuration:0.4 animations:^{
          self.blankslateView.layer.opacity = 0.0;
        }];
      }];
      [self mv_performBlock:^{
        if(!self.blankslateDisplayed)
        {
          [self.blankslateView removeFromSuperview];
        }
      } afterDelay:(animated ? 0.4 : 0)];
    }
    self.blankslateDisplayed = showsBlankslate;
  }
}

- (void)updateFromOnline
{
  if(self.textView)
  {
    self.textView.editable = (self.state == kMVChatSectionViewStateOnline);
    self.textView.hidden = (self.state != kMVChatSectionViewStateOnline);
  }
  if(self.state == kMVChatSectionViewStateOffline)
  {
    CGRect frame = self.offlineButton.frame;
    frame.origin.x = round((self.bottomBarView.frame.size.width - frame.size.width) / 2);
    self.offlineButton.frame = frame;
    if(!self.offlineButton.superview)
      [self.bottomBarView addSubview:self.offlineButton];
  }
  else
  {
    [self.offlineButton removeFromSuperview];
  }
  if(self.state == kMVChatSectionViewStateConnecting)
  {
    CGRect frame = self.connectingSpinner.frame;
    frame.origin.x = round((self.bottomBarView.frame.size.width - frame.size.width) / 2);
    self.connectingSpinner.frame = frame;
    if(!self.connectingSpinner.superview)
    {
      [self.bottomBarView addSubview:self.connectingSpinner];
      [self mv_performBlock:^{
        [self.connectingSpinner startAnimating];
      } afterDelay:0.01];
    }
  }
  else
  {
    [self.connectingSpinner stopAnimating];
    [self.connectingSpinner removeFromSuperview];
  }
  [self updateBottomBarViewFrame];
}

- (void)updateBottomBarViewFrame
{
  [self.bottomBarView removeAllAnimations];
  CGRect rect = CGRectMake(0, 0, self.frame.size.width, 30);
  if(self.textView && self.state == kMVChatSectionViewStateOnline)
  {
    rect.size.height = self.textView.frame.size.height + 1;
  }
  [self.bottomBarView setFrame:rect];
  [self updateDiscussionViewFrame];
}

- (void)updateDiscussionViewFrame
{
  if(self.discussionView)
    self.discussionView.frame = CGRectMake(0, self.bottomBarView.frame.size.height,
                                           self.frame.size.width,
                                           self.frame.size.height -
                                           self.bottomBarView.frame.size.height -
                                           ([self.tabsBarView countTabs] > 1 ? 23 : 0));
}

- (void)setDiscussionViewFront:(BOOL)front
{
  if(self.discussionView)
    self.discussionView.layer.zPosition = (front ? 3 : 1);
}

@end
