#import "MVDiscussionView.h"
#import "MVDiscussionMessageItem.h"
#import "MVDiscussionMessageView.h"
#import "MVRoundedTextView.h"
#import "MVActivityIndicatorView.h"
#import "NSObject+PerformBlockAfterDelay.h"
#import "NSEvent+CharacterDetection.h"
#import "MVURLKit.h"

#define kMVDiscussionViewAnimationDuration 0.25
#define kMVDiscussionViewLoadingMessagesHeight 40

@interface TUIScrollKnob : TUIView
@end

@interface TUIScrollView ()
- (TUIScrollKnob*)verticalScrollKnob;
- (TUIScrollKnob*)horizontalScrollKnob;
@end

@interface _MVDiscussionContentView : TUIView

@end

@interface MVDiscussionView () <QLPreviewPanelDataSource,
                                 QLPreviewPanelDelegate,
                                 MVDiscussionMessageItemDelegate>

@property (strong, readwrite) _MVDiscussionContentView *contentView;
@property (strong, readwrite) TUIView *animatedView;
@property (strong, readwrite) NSMutableArray *items;
@property (strong, readwrite) NSMutableDictionary *visibleViews;
@property (strong, readwrite) NSMutableArray *reusableViews;
@property (strong, readwrite) TUITextRenderer *textRenderer;
@property (readwrite) CGSize lastSize;
@property (readwrite) int ownMessagesAnimating;
@property (readwrite) float cachedExpectedHeight;
@property (readwrite) BOOL shouldProcessOffsets;
@property (strong, readwrite) MVDiscussionMessageItem *selectionStartItem;
@property (readwrite) int selectionStartIndex;
@property (strong, readwrite) MVDiscussionMessageItem *selectionEndItem;
@property (readwrite) int selectionEndIndex;
@property (strong, readwrite) MVDiscussionMessageItem *selectedItem;
@property (strong, readwrite) MVActivityIndicatorView *topActivityIndicatorView;
@property (strong, readwrite) MVActivityIndicatorView *bottomActivityIndicatorView;
@property (strong, readwrite) NSMutableArray *pendingDiscussionItems;
@property (strong, readwrite) NSMutableArray *tmpItems;

- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
                 animated:(BOOL)animated
                      top:(BOOL)top;
- (MVDiscussionMessageView*)lastVisibleView;
- (void)setViewsDisplayAsFirstResponder:(BOOL)firstResponder;
- (void)toggleQuicklook;
- (void)scrollToItem:(MVDiscussionMessageItem*)item animated:(BOOL)animated;
- (BOOL)hasSelection;
- (void)updateSelectedRangeForView:(MVDiscussionMessageView*)view;
- (void)layoutViewsWithAdditionnalHeight:(int)additionnalHeight;
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;
- (CGSize)sizeForIndexPath:(int)indexPath;
- (CGRect)rectForIndexPath:(int)indexPath;
- (void)enqueueReusableView:(MVDiscussionMessageView*)view;
- (MVDiscussionMessageView*)dequeueReusableView;
- (MVDiscussionMessageView*)createViewForIndexPath:(int)indexPath;
- (int)zPositionForIndexPath:(int)indexPath
                     andView:(MVDiscussionMessageView*)view;
- (int)expectedHeight;

@end

@implementation MVDiscussionView

@synthesize contentView                   = contentView_,
            animatedView                  = animatedView_,
            items                         = items_,
            visibleViews                  = visibleViews_,
            reusableViews                 = reusableViews_,
            textRenderer                  = textRenderer_,
            lastSize                      = lastSize_,
            ownMessagesAnimating          = ownMessagesAnimating_,
            cachedExpectedHeight          = cachedExpectedHeight_,
            shouldProcessOffsets          = shouldProcessOffsets_,
            selectionStartItem            = selectionStartItem_,
            selectionStartIndex           = selectionStartIndex_,
            selectionEndItem              = selectionEndItem_,
            selectionEndIndex             = selectionEndIndex_,
            selectedItem                  = selectedItem_,
            topActivityIndicatorView      = topActivityIndicatorView_,
            bottomActivityIndicatorView   = bottomActivityIndicatorView_,
            pendingDiscussionItems        = pendingDiscussionItems_,
            tmpItems                      = tmpItems_,
            delegate                      = delegate_,
            style                         = style_,
            hasNotLoadedPreviousItems     = hasNotLoadedPreviousItems_,
            hasNotLoadedNextItems         = hasNotLoadedNextItems_,
            allowsBlankslate              = allowsBlankslate_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.clipsToBounds = NO;
    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];
    self.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
    self.scrollEnabled = YES;
    self.alwaysBounceVertical = YES;

    contentView_ = [[_MVDiscussionContentView alloc] initWithFrame:self.bounds];
    contentView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    [self addSubview:contentView_];
    animatedView_ = [[TUIView alloc] initWithFrame:self.bounds];
    animatedView_.autoresizingMask = TUIViewAutoresizingNone;
    [contentView_ addSubview:animatedView_];
    items_ = [[NSMutableArray alloc] init];
    visibleViews_ = [[NSMutableDictionary alloc] init];
    reusableViews_ = [[NSMutableArray alloc] init];
    textRenderer_ = [[TUITextRenderer alloc] init];
    lastSize_ = CGSizeZero;
    ownMessagesAnimating_ = 0;
    cachedExpectedHeight_ = -1;
    shouldProcessOffsets_ = NO;
    selectionStartItem_ = nil;
    selectionStartIndex_ = -1;
    selectionEndItem_ = nil;
    selectionEndIndex_ = -1;
    selectedItem_ = nil;
    topActivityIndicatorView_ = nil;
    bottomActivityIndicatorView_ = nil;
    delegate_ = nil;
    style_ = kMVDiscussionViewStyleBlueGradient;
    hasNotLoadedPreviousItems_ = NO;
    hasNotLoadedNextItems_ = NO;
    allowsBlankslate_ = YES;
    pendingDiscussionItems_ = [NSMutableArray array];
    tmpItems_ = [NSMutableArray array];

    [self registerForDraggedTypes:[NSArray arrayWithObjects:
                                   NSPasteboardTypeTIFF,
                                   NSPasteboardTypePNG,
                                   NSFilenamesPboardType,
                                   nil]];

    [self addObserver:self forKeyPath:@"selectedItem" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"hasNotLoadedPreviousItems" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"hasNotLoadedNextItems" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"ownMessagesAnimating" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeObserver:self forKeyPath:@"selectedItem"];
  [self removeObserver:self forKeyPath:@"hasNotLoadedPreviousItems"];
  [self removeObserver:self forKeyPath:@"hasNotLoadedNextItems"];
  [self removeObserver:self forKeyPath:@"ownMessagesAnimating"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([keyPath isEqualToString:@"selectedItem"])
  {
    if ([QLPreviewPanel sharedPreviewPanelExists] &&
        [[QLPreviewPanel sharedPreviewPanel] isVisible])
    {
      [[QLPreviewPanel sharedPreviewPanel] reloadData];
    }
  }
  else if([keyPath isEqualToString:@"hasNotLoadedPreviousItems"] ||
          [keyPath isEqualToString:@"hasNotLoadedNextItems"])
  {
    self.cachedExpectedHeight = -1;
    self.shouldProcessOffsets = YES;
    [self layoutSubviews];
  }
  else if([keyPath isEqualToString:@"ownMessagesAnimating"])
  {
    if(self.ownMessagesAnimating <= 0 &&
       self.pendingDiscussionItems.count > 0)
    {
      [self willChangeValueForKey:@"countItems"];
      MVDiscussionMessageItem *item;
      for(item in self.pendingDiscussionItems)
      {
        [self.items addObject:item];
      }
      [self.pendingDiscussionItems removeAllObjects];
      [self didChangeValueForKey:@"countItems"];
      self.cachedExpectedHeight = -1;
      self.shouldProcessOffsets = YES;
      [self layoutSubviews:YES];
    }
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow
{
  [super willMoveToWindow:newWindow];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self name:NSWindowDidEndLiveResizeNotification object:self.nsWindow];
  [nc addObserver:self
         selector:@selector(endLiveResize)
             name:NSWindowDidEndLiveResizeNotification
           object:newWindow];
}

- (int)countItems
{
  return self.items.count;
}

- (void)removeAllDiscussionItems
{
  [self resetSelection];
  [self resetSelectedItem];
  [self willChangeValueForKey:@"countItems"];
  [self.items removeAllObjects];
  [self didChangeValueForKey:@"countItems"];
}

- (void)insertDiscussionItemAtTop:(MVDiscussionMessageItem*)discussionItem
{
  [self addDiscussionItem:discussionItem animated:NO top:YES];
}

- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
{
  [self addDiscussionItem:discussionItem animated:YES top:NO];
}

- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
                 animated:(BOOL)animated
{
  [self addDiscussionItem:discussionItem animated:animated top:NO];
}

- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
                 animated:(BOOL)animated
                      top:(BOOL)top
{
  animated &= (self.contentOffset.y > -10);

  if(!top)
    discussionItem.previousItem = [self.items lastObject];
  else if(self.items.count > 0)
  {
    MVDiscussionMessageItem *firstItem = [self.items objectAtIndex:0];
    firstItem.previousItem = discussionItem;
  }
  if(animated)
  {
    discussionItem.animated = animated;
    CGSize size = [MVDiscussionMessageView sizeForItem:discussionItem
                                     constrainedToWidth:self.bounds.size.width
                                           textRenderer:self.textRenderer
                                               inWindow:self.nsWindow];
    discussionItem.animatingFromPoint = CGPointMake(0, -size.height);
  }
  discussionItem.delegate = self;
  [self willChangeValueForKey:@"countItems"];
  if(!top)
  {
    if(discussionItem.animationStyle != kMVDiscussionMessageAnimationStyleSentMessage &&
       self.ownMessagesAnimating > 0)
    {
      [self.pendingDiscussionItems addObject:discussionItem];
    }
    else
    {
      [self.items addObject:discussionItem];
    }
  }
  else
  {
    [self.items insertObject:discussionItem atIndex:0];
  }

  // update visibleViews indexPaths
  NSMutableDictionary *newVisibleViews = [NSMutableDictionary dictionary];
  NSNumber *indexPath;
  MVDiscussionMessageView *view;
  for(indexPath in self.visibleViews)
  {
    view = [self.visibleViews objectForKey:indexPath];
    if([self.items containsObject:view.item])
    {
      [newVisibleViews setObject:view
                          forKey:[NSNumber numberWithInt:[self.items indexOfObject:view.item]]];
    }
    else
    {
      [self enqueueReusableView:view];
      [view removeFromSuperview];
    }
  }
  self.visibleViews = newVisibleViews;

  [self didChangeValueForKey:@"countItems"];
  self.cachedExpectedHeight = -1;
  self.shouldProcessOffsets = YES;
}

- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
      animateFromTextView:(MVRoundedTextView*)textView
{
  discussionItem.animated = YES;
  CGSize size = [MVDiscussionMessageView sizeForItem:discussionItem
                                   constrainedToWidth:self.bounds.size.width
                                         textRenderer:self.textRenderer
                                             inWindow:self.nsWindow];
  CGPoint point = [self convertPoint:textView.frame.origin fromView:textView.superview];
  discussionItem.animationStyle = kMVDiscussionMessageAnimationStyleSentMessage;
  discussionItem.animatingFromPoint = CGPointMake(- (self.bounds.size.width - size.width) +
                                                  + (point.x - 41),
                                                  point.y - 1);
  [self addDiscussionItem:discussionItem animated:NO top:NO];
}

- (void)removeDiscussionItem:(MVDiscussionMessageItem*)discussionItem
{
  if([self.items containsObject:discussionItem])
  {
    [self willChangeValueForKey:@"countItems"];
    // find next item
    int index = [self.items indexOfObject:discussionItem];
    MVDiscussionMessageItem *nextItem = nil;
    if(index < self.items.count - 1)
    {
      nextItem = [self.items objectAtIndex:index + 1];
    }
    [self.items removeObject:discussionItem];
    if(nextItem)
    {
      if(index > 0)
        nextItem.previousItem = [self.items objectAtIndex:index - 1];
      else
        nextItem.previousItem = nil;
    }
    [self didChangeValueForKey:@"countItems"];

    // update visibleViews indexPaths
    NSMutableDictionary *newVisibleViews = [NSMutableDictionary dictionary];
    NSNumber *indexPath;
    MVDiscussionMessageView *view;
    for(indexPath in self.visibleViews)
    {
      view = [self.visibleViews objectForKey:indexPath];
      if([self.items containsObject:view.item])
      {
        [newVisibleViews setObject:view
                            forKey:[NSNumber numberWithInt:[self.items indexOfObject:view.item]]];
      }
      else if(view.item == discussionItem)
      {
        TUIView *maskView = [[TUIView alloc] initWithFrame:view.bounds];
        maskView.drawRect = ^(TUIView *view, CGRect rect)
        {
          [[NSColor blackColor] set];
          [NSBezierPath fillRect:view.bounds];
        };
        view.layer.mask = maskView.layer;
        [self.tmpItems addObject:view];
        [self.tmpItems addObject:maskView];

        [self mv_performBlock:^{
          [TUIView animateWithDuration:kMVDiscussionViewAnimationDuration animations:^{
            CGRect frame = maskView.frame;
            frame.origin.y = -frame.size.height;
            maskView.frame = frame;
            view.layer.opacity = 0.0;
          }];
          [self mv_performBlock:^{
            view.layer.mask = nil;
            [self enqueueReusableView:view];
            [view removeFromSuperview];
            view.layer.opacity = 1.0;
            [self.tmpItems removeObject:view];
            [self.tmpItems removeObject:maskView];
          } afterDelay:kMVDiscussionViewAnimationDuration];
        } afterDelay:0.01];
      }
    }
    self.visibleViews = newVisibleViews;

    self.cachedExpectedHeight = -1;
    self.shouldProcessOffsets = YES;
  }
}

- (MVDiscussionMessageItem*)discussionItemAtIndex:(int)index
{
  return [self.items objectAtIndex:index];
}

- (MVDiscussionMessageItem*)discussionItemForRepresentedObject:(NSObject*)representedObject
{
  MVDiscussionMessageItem *item;
  for(item in self.items)
  {
    if(item.representedObject == representedObject)
      return item;
  }
  return nil;
}

- (NSOrderedSet*)discussionItemsForRepresentedObject:(NSObject*)representedObject
{
  NSMutableOrderedSet *mutableSet = [NSMutableOrderedSet orderedSet];
  MVDiscussionMessageItem *item;
  for(item in self.items)
  {
    if([item.representedObject isEqual:representedObject] ||
       ([item.representedObject isKindOfClass:[NSManagedObject class]] &&
        [representedObject isKindOfClass:[NSManagedObject class]] &&
        [((NSManagedObject*)(item.representedObject)).objectID isEqualTo:
         ((NSManagedObject*)(representedObject)).objectID]))
    {
      [mutableSet addObject:item];
    }
  }
  return mutableSet;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self layoutSubviews:NO];
}

- (void)layoutSubviews:(BOOL)animated
{
  BOOL keepScrollAtBottom = (self.contentOffset.y > -10);
  if(!keepScrollAtBottom)
    animated = NO;

  if(animated && !self.isVisibleInWindow)
    animated = NO;

  MVDiscussionMessageView *lastVisibleView = self.lastVisibleView;
  int lastVisibleOffset = 0;
  if(lastVisibleView)
    lastVisibleOffset = lastVisibleView.item.offset;

  CGRect bounds = self.bounds;
  if(!CGSizeEqualToSize(bounds.size, self.lastSize))
     self.cachedExpectedHeight = -1;

  if(self.ownMessagesAnimating == 0)
  {
    if([self.delegate respondsToSelector:@selector(discussionViewShouldNotBeFront:)])
      [self.delegate discussionViewShouldNotBeFront:self];
  }

  CGRect frame = self.contentView.frame;

  CGSize size;
  MVDiscussionMessageItem *item;
  int i;
  BOOL offsetChanged = NO;
  NSNumber *indexPath;
  if(!CGSizeEqualToSize(self.contentSize, frame.size) || self.shouldProcessOffsets)
  {
    // process offsets
    int count = (int)self.items.count;
    int y = [self expectedHeight];
    if(self.hasNotLoadedPreviousItems)
      y -= kMVDiscussionViewLoadingMessagesHeight;
    for(i=0;i<count;i++)
    {
      size = [self sizeForIndexPath:i];
      y -= size.height;
      item = [self.items objectAtIndex:i];
      y -= [MVDiscussionMessageView marginTopForItem:item];
      if(item.offset != y)
      {
        item.offset = y;
        offsetChanged = YES;
      }
    }
    self.shouldProcessOffsets = NO;
  }

  CGPoint contentOffset = self.contentOffset;
  float contentHeight = frame.size.height = [self expectedHeight];
  if(frame.size.height < self.bounds.size.height)
    frame.size.height = self.bounds.size.height;
  self.contentView.frame = frame;
  CGRect animatedFrame = self.animatedView.frame;
  if(animatedFrame.size.height != contentHeight)
  {
    animatedFrame.size.height = contentHeight;
    animatedFrame.size.width = frame.size.width;
//    [self.animatedView removeAllAnimations];
    self.animatedView.frame = animatedFrame;
  }

  if(!CGSizeEqualToSize(self.contentSize, frame.size))
  {
    self.contentSize = frame.size;
    if(!keepScrollAtBottom)
    {
      // find additionnal height added below our last view
      int newLastVisibleOffset = 0;
      if(lastVisibleView)
        newLastVisibleOffset = lastVisibleView.item.offset;
      float additionnalHeight = newLastVisibleOffset - lastVisibleOffset;
      contentOffset.y -= additionnalHeight;
    }
    self.contentOffset = contentOffset;

    if(keepScrollAtBottom)
      self.scrollIndicatorStyle = TUIScrollViewIndicatorVisibleNever;
  }

  // check if we need to redisplay current visible views (if width has changed)
	if(!CGSizeEqualToSize(bounds.size, self.lastSize) || offsetChanged)
  {
    MVDiscussionMessageView *view;
    for(indexPath in self.visibleViews)
    {
      i = [indexPath intValue];
			view = [self.visibleViews objectForKey:indexPath];
      CGRect rrect = [self rectForIndexPath:i];
      [TUIView setAnimationsEnabled:(animated || view.item.animating) block:^{
        [TUIView animateWithDuration:kMVDiscussionViewAnimationDuration animations:^{
          view.frame = rrect;
        }];
      }];
			view.layer.zPosition = [self zPositionForIndexPath:i andView:view];
		}
    self.lastSize = bounds.size;
  }

  // add/remove visible views + layout
  [self layoutViewsWithAdditionnalHeight:0];

  // display activity indicator views if needed
  if(self.hasNotLoadedPreviousItems &&
     CGRectIntersectsRect(self.visibleRect, CGRectMake(0,
                                                       self.contentSize.height -
                                                       kMVDiscussionViewLoadingMessagesHeight,
                                                       self.contentSize.width,
                                                       kMVDiscussionViewLoadingMessagesHeight)))
  {
    if(!self.topActivityIndicatorView)
    {
      self.topActivityIndicatorView = [[MVActivityIndicatorView alloc] initWithFrame:CGRectZero];
      self.topActivityIndicatorView.style = kMVActivityIndicatorStyleBlue;
    }
    CGRect frame = self.topActivityIndicatorView.frame;
    frame.origin.x = round((self.contentSize.width - frame.size.width) / 2);
    if(self.items.count > 0)
      frame.origin.y = round((kMVDiscussionViewLoadingMessagesHeight - frame.size.height) / 2 +
                             self.contentSize.height - kMVDiscussionViewLoadingMessagesHeight);
    else
      frame.origin.y = round((self.contentSize.height - frame.size.height) / 2);
    self.topActivityIndicatorView.frame = frame;
    [self addSubview:self.topActivityIndicatorView];
    [self.topActivityIndicatorView startAnimating];

//    if(self.isBouncing)
//    {
      if([self.delegate respondsToSelector:@selector(discussionViewShouldLoadPreviousItems:)])
        [self.delegate discussionViewShouldLoadPreviousItems:self];
//    }
  }
  else if(self.topActivityIndicatorView)
  {
    [self.topActivityIndicatorView stopAnimating];
    [self.topActivityIndicatorView removeFromSuperview];
  }

  if(self.hasNotLoadedNextItems &&
     CGRectIntersectsRect(self.visibleRect, CGRectMake(0, 0,
                                                       self.contentSize.width,
                                                       kMVDiscussionViewLoadingMessagesHeight)) &&
     self.items.count > 0)
  {
    if(!self.bottomActivityIndicatorView)
    {
      self.bottomActivityIndicatorView = [[MVActivityIndicatorView alloc] initWithFrame:CGRectZero];
      self.bottomActivityIndicatorView.style = kMVActivityIndicatorStyleBlue;
    }
    CGRect frame = self.bottomActivityIndicatorView.frame;
    frame.origin.x = round((self.contentSize.width - frame.size.width) / 2);
    frame.origin.y = round((kMVDiscussionViewLoadingMessagesHeight - frame.size.height) / 2);
    self.bottomActivityIndicatorView.frame = frame;
    [self addSubview:self.bottomActivityIndicatorView];
    [self.bottomActivityIndicatorView startAnimating];

//    if(self.isBouncing)
//    {
      if([self.delegate respondsToSelector:@selector(discussionViewShouldLoadNextItems:)])
        [self.delegate discussionViewShouldLoadNextItems:self];
//    }
  }
  else if(self.bottomActivityIndicatorView)
  {
    [self.bottomActivityIndicatorView stopAnimating];
    [self.bottomActivityIndicatorView removeFromSuperview];
  }

  // update start/end percents
  if(self.style == kMVDiscussionViewStyleBlueGradient)
  {
    MVDiscussionMessageView *view;
    CGRect rect;
    float p1;
    float p2;
    for(indexPath in self.visibleViews)
    {
      view = [self.visibleViews objectForKey:indexPath];
      rect = [self convertRect:view.frame fromView:self.contentView];
      rect.origin.y += self.contentOffset.y;
      p1 = rect.origin.y / self.bounds.size.height;
      p2 = (rect.origin.y + rect.size.height) / self.bounds.size.height;
      [view setBackgroundStartPercent:p1 endPercent:p2];
    }
  }

  [self.verticalScrollKnob layoutSubviews];
  self.scrollIndicatorStyle = TUIScrollViewIndicatorVisibleDefault;
}

- (void)resetSelection
{
  self.selectionStartItem = nil;
  self.selectionStartIndex = -1;
  self.selectionEndItem = nil;
  self.selectionEndIndex = -1;

  NSNumber *indexPath;
  MVDiscussionMessageView *view;
  for(indexPath in self.visibleViews)
  {
    view = [self.visibleViews objectForKey:indexPath];
    [view.textRenderer resetSelection];
  }
}

- (void)selectUp
{
  int i = (int)[self.items count] - 1;
  MVDiscussionMessageView *view;
  MVDiscussionMessageItem *oldSelectedItem = self.selectedItem;

  if(self.selectedItem)
  {
    i = (int)[self.items indexOfObject:self.selectedItem] - 1;
  }

  BOOL found = NO;
  MVDiscussionMessageItem *item;
  while(i >= 0 && !found)
  {
    item = [self.items objectAtIndex:i];
    if(((item.type == kMVDiscussionMessageTypeImage ||
         item.type == kMVDiscussionMessageTypeRemoteImage)
        && item.image) ||
       ((item.type == kMVDiscussionMessageTypeFile ||
         item.type == kMVDiscussionMessageTypeRemoteFile) && item.asset.isExisting))
    {
      self.selectedItem = item;
      self.selectedItem.selected = YES;
      view = [self.visibleViews objectForKey:[NSNumber numberWithInt:i]];
      if(view)
        [view setNeedsDisplay];
      [self scrollToItem:self.selectedItem animated:YES];
      found = YES;
    }
    i--;
  }

  if(oldSelectedItem && found)
  {
    oldSelectedItem.selected = NO;
    i = (int)[self.items indexOfObject:oldSelectedItem];
    view = [self.visibleViews objectForKey:[NSNumber numberWithInt:i]];
    if(view)
      [view setNeedsDisplay];
  }
}

- (void)selectDown
{
  int i = 0;
  MVDiscussionMessageView *view;
  MVDiscussionMessageItem *oldSelectedItem = self.selectedItem;

  if(self.selectedItem)
  {
    i = (int)[self.items indexOfObject:self.selectedItem] + 1;
  }

  BOOL found = NO;
  MVDiscussionMessageItem *item;
  while(i < [self.items count] && !found)
  {
    item = [self.items objectAtIndex:i];
    if(((item.type == kMVDiscussionMessageTypeImage ||
         item.type == kMVDiscussionMessageTypeRemoteImage)
        && item.image) ||
       ((item.type == kMVDiscussionMessageTypeFile ||
         item.type == kMVDiscussionMessageTypeRemoteFile) && item.asset.isExisting))
    {
      self.selectedItem = item;
      self.selectedItem.selected = YES;
      view = [self.visibleViews objectForKey:[NSNumber numberWithInt:i]];
      if(view)
        [view setNeedsDisplay];
      [self scrollToItem:self.selectedItem animated:YES];
      found = YES;
    }
    i++;
  }

  if(oldSelectedItem &&
     (found ||
      [self.delegate respondsToSelector:@selector(discussionViewShouldGiveFocusToTextField:)]))
  {
    oldSelectedItem.selected = NO;
    i = (int)[self.items indexOfObject:oldSelectedItem];
    view = [self.visibleViews objectForKey:[NSNumber numberWithInt:i]];
    if(view)
      [view setNeedsDisplay];
  }

  if(!found &&
     [self.delegate respondsToSelector:@selector(discussionViewShouldGiveFocusToTextField:)])
  {
    [self scrollToBottomAnimated:YES];
    [self.delegate discussionViewShouldGiveFocusToTextField:self];
  }
}

- (void)resetSelectedItem
{
  if(self.selectedItem)
  {
    self.selectedItem.selected = NO;
    int i = (int)[self.items indexOfObject:self.selectedItem];
    MVDiscussionMessageView *view = [self.visibleViews objectForKey:[NSNumber numberWithInt:i]];
    if(view)
      [view setNeedsDisplay];
    self.selectedItem = nil;
  }
}

- (void)scrollToCenterItem:(MVDiscussionMessageItem*)discussionItem
                  animated:(BOOL)animated
{
  int indexPath = [self.items indexOfObject:discussionItem];
  CGRect rect = [self rectForIndexPath:indexPath];
  rect = CGRectInset(rect, 0, -(self.frame.size.height - rect.size.height) / 2);
  [self scrollRectToVisible:rect animated:NO];
}

- (void)setDelegate:(NSObject<MVDiscussionViewDelegate> *)delegate
{
  if(delegate == delegate_)
    return;
  delegate_ = delegate;
  [super setDelegate:delegate];
}

- (MVDiscussionMessageItem*)lastVisibleItemHavingMessage
{
  CGRect visibleRect = self.visibleRect;
  NSNumber *indexPath;
  float minY = INTMAX_MAX;
  MVDiscussionMessageItem *minItem = nil;
  MVDiscussionMessageItem *item;
  CGRect rect;
  for(indexPath in self.visibleViews)
  {
    if(indexPath.intValue < 0 || indexPath.intValue >= self.items.count)
      continue;
    item = [self.items objectAtIndex:indexPath.intValue];
    if(!item.representedObject)
      continue;
    rect = [self rectForIndexPath:indexPath.intValue];
    if(CGRectIntersection(visibleRect, rect).size.height >=
       MIN(visibleRect.size.height - 20, rect.size.height - 6))
    {
      if(rect.origin.y < minY)
      {
        minY = rect.origin.y;
        minItem = item;
      }
    }
  }
  return minItem;
}

- (NSString*)selectedString
{
  if(![self hasSelection])
    return @"";
  MVDiscussionMessageItem *startItem = self.selectionStartItem;
  int startIndex = self.selectionStartIndex;
  MVDiscussionMessageItem *endItem = self.selectionEndItem;
  int endIndex = self.selectionEndIndex;
  int fromIndexPath = (int)[self.items indexOfObject:self.selectionStartItem];
  int toIndexPath = (int)[self.items indexOfObject:self.selectionEndItem];
  if(fromIndexPath > toIndexPath ||
     (fromIndexPath == toIndexPath &&
      startIndex > endIndex))
  {
    int tmp = fromIndexPath;
    fromIndexPath = toIndexPath;
    toIndexPath = tmp;

    startItem = self.selectionEndItem;
    startIndex = self.selectionEndIndex;
    endItem = self.selectionStartItem;
    endIndex = self.selectionStartIndex;
  }

  NSMutableString *string = [[NSMutableString alloc] init];
  MVDiscussionMessageItem *item;
  for(int i = fromIndexPath; i <= toIndexPath; i++)
  {
    item = [self.items objectAtIndex:i];
    if(item.type == kMVDiscussionMessageTypeText ||
       item.type == kMVDiscussionMessageTypeTweet)
    {
      if(string.length != 0)
        [string appendString:@"\n"];

      NSRange range;
      if(item == startItem && item == endItem)
      {
        range = NSMakeRange(startIndex, endIndex - startIndex);
      }
      else if(item == startItem)
      {
        range = NSMakeRange(startIndex, item.message.length - startIndex);
      }
      else if(item == endItem)
      {
        range = NSMakeRange(0, endIndex);
      }
      else
      {
        range = NSMakeRange(0, item.message.length);
      }
      [string appendString:[item formattedMessageSubstringWithRange:range]];
    }
  }
  return string;
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)event onSubview:(TUIView *)subview
{
  [super mouseDown:event onSubview:subview];
  if(![subview isKindOfClass:[MVDiscussionMessageView class]])
    return;

  [self resetSelectedItem];

  MVDiscussionMessageView *view = (MVDiscussionMessageView*)subview;
  if(([event modifierFlags] & NSShiftKeyMask) == 0)
  {
    [self resetSelection];
    self.selectionStartItem = view.item;
  }
  else
    [view.textRenderer resetSelection];
  self.selectionEndItem = view.item;

  if(view.item.type == kMVDiscussionMessageTypeTweet ||
     view.item.type == kMVDiscussionMessageTypeText)
  {
    [view.textRenderer mouseDown:event];

    NSRange selectedRange = view.textRenderer.selectedRange;
    if(([event modifierFlags] & NSShiftKeyMask) == 0)
    {
      self.selectionStartIndex = (int)(selectedRange.location);
    }
    self.selectionEndIndex = (int)(selectedRange.location + selectedRange.length);

    CGRect rect = [view.textRenderer firstRectForCharacterRange:CFRangeMake(selectedRange.location +
                                                                            selectedRange.length,
                                                                            1)];
    rect.origin.x = floor(rect.origin.x-2);
    rect.size.width += 3;
    CGPoint pointInView = [view convertPoint:[self.nsView convertPoint:event.locationInWindow
                                                              fromView:nil]
                                    fromView:nil];
    if(CGRectContainsPoint(rect, pointInView))
    {
      view.activeLinkIndex = self.selectionStartIndex;
    }
    else
    {
      view.activeLinkIndex = -1;
    }
    [view setNeedsDisplay];
  }

  if(([event modifierFlags] & NSShiftKeyMask))
  {
    MVDiscussionMessageView *view;
    NSNumber *indexPath;
    for(indexPath in self.visibleViews)
    {
      view = [self.visibleViews objectForKey:indexPath];
      if((view.item.type == kMVDiscussionMessageTypeTweet ||
          view.item.type == kMVDiscussionMessageTypeText))
      {
        [self updateSelectedRangeForView:view];
      }
    }
  }

  if(((view.item.type == kMVDiscussionMessageTypeImage ||
       view.item.type == kMVDiscussionMessageTypeRemoteImage)
      && view.item.image && view.item.asset.uploadFinished) ||
     ((view.item.type == kMVDiscussionMessageTypeFile ||
       view.item.type == kMVDiscussionMessageTypeRemoteFile) && view.item.asset.isExisting &&
       view.item.asset.uploadFinished))
  {
    NSPoint pointInView = [self.nsView convertPoint:event.locationInWindow fromView:nil];
    pointInView = [view convertPoint:pointInView fromView:nil];
    if(CGRectContainsPoint(view.bubbleRect, pointInView))
    {
      self.selectedItem = view.item;
      self.selectedItem.selected = YES;
      [view setNeedsDisplay];
    }
  }

  if(event.clickCount >= 2 &&
     ((view.item.type == kMVDiscussionMessageTypeRemoteImage ||
       view.item.type == kMVDiscussionMessageTypeRemoteFile) ||
      ((view.item.type == kMVDiscussionMessageTypeImage ||
        view.item.type == kMVDiscussionMessageTypeFile) && view.item.asset.uploadFinished)))
  {
    NSPoint pointInView = [self.nsView convertPoint:event.locationInWindow fromView:nil];
    pointInView = [view convertPoint:pointInView fromView:nil];
    if(CGRectContainsPoint(view.bubbleRect, pointInView))
    {
      [view.item openURL];
    }
  }

  [self.nsWindow tui_makeFirstResponder:self];
}

- (void)mouseDragged:(NSEvent *)event onSubview:(TUIView *)subview
{
  [super mouseDragged:event onSubview:subview];
  if(![subview isKindOfClass:[MVDiscussionMessageView class]])
    return;

  MVDiscussionMessageView *view = (MVDiscussionMessageView*)subview;
  if(view.activeLinkIndex != -1)
  {
    view.activeLinkIndex = -1;
    [view setNeedsDisplay];
  }

  CGPoint point = event.locationInWindow;
  point = [self.nsView convertPoint:point fromView:nil];
  point = [self convertPoint:point fromView:nil];

  int startIndexPath = (int)[self.items indexOfObject:self.selectionStartItem];

  NSNumber *indexPath;
  for(indexPath in self.visibleViews)
  {
    view = [self.visibleViews objectForKey:indexPath];
    if((view.item.type == kMVDiscussionMessageTypeTweet ||
        view.item.type == kMVDiscussionMessageTypeText))
    {
      TUITextRenderer *textRenderer = view.textRenderer;
      NSRange selectedRange = textRenderer.selectedRange;
      int len = (int)[textRenderer.attributedString length];
      if(view != subview)
      {
        if([indexPath intValue] < startIndexPath &&
           selectedRange.location + selectedRange.length != len)
        {
          textRenderer.selection = NSMakeRange(len, 0);
        }
        else if([indexPath intValue] > startIndexPath &&
                selectedRange.location != 0)
        {
          textRenderer.selection = NSMakeRange(0, 0);
        }
      }
      [textRenderer mouseDragged:event];

      if(CGRectContainsPoint(view.frame, point))
      {
        self.selectionEndItem = view.item;
        selectedRange = textRenderer.selectedRange;
        if(startIndexPath > [indexPath intValue] ||
           (startIndexPath == [indexPath intValue] &&
            self.selectionStartIndex > selectedRange.location))
          self.selectionEndIndex = (int)(selectedRange.location);
        else
          self.selectionEndIndex = (int)(selectedRange.location + selectedRange.length);
      }
    }
  }

  // auto scrolling
  CGRect visible = [self visibleRect];
  CGPoint location = [self.superview convertPoint:event.locationInWindow fromView:nil];
  location = CGPointMake(location.x, MAX(0, MIN(visible.size.height, location.y)));
  [self beginContinuousScrollForDragAtPoint:location animated:TRUE];
}

- (void)mouseUp:(NSEvent *)event fromSubview:(TUIView *)subview
{
  [super mouseUp:event fromSubview:subview];

  [self endContinuousScrollAnimated:YES];

  if([subview isKindOfClass:[MVDiscussionMessageView class]])
  {
    MVDiscussionMessageView *view = (MVDiscussionMessageView*)subview;
    if(view.item.type == kMVDiscussionMessageTypeNotification)
    {
      CGPoint point = event.locationInWindow;
      point = [self.nsView convertPoint:point fromView:nil];
      point = [self convertPoint:point fromView:nil];
      if(CGRectContainsPoint(view.frame, point) && view.item.notificationClickable)
      {
        if([self.delegate respondsToSelector:@selector(discussionView:didClickNotification:)])
          [self.delegate discussionView:self didClickNotification:view.item];
      }
    }
    else if(self.selectionStartIndex > -1 && ![self hasSelection])
    {
      int mouseUpIndex = (int)[view.textRenderer stringIndexForEvent:event];
      int len = (int)[[view.textRenderer.attributedString string] length];
      if(mouseUpIndex >= 0 && mouseUpIndex < len &&
         self.selectionStartIndex >= 0 && self.selectionStartIndex < len &&
         view.activeLinkIndex == self.selectionStartIndex)
      {
        NSURL *startUrl = [view.textRenderer.attributedString attribute:NSLinkAttributeName
                                                                atIndex:self.selectionStartIndex
                                                         effectiveRange:NULL];
        NSURL *url = [view.textRenderer.attributedString attribute:NSLinkAttributeName
                                                           atIndex:mouseUpIndex
                                                    effectiveRange:NULL];
        if(startUrl && url && startUrl == url)
        {
          [[NSWorkspace sharedWorkspace] openURL:url];
        }
      }
      if(view.activeLinkIndex != -1)
      {
        view.activeLinkIndex = -1;
        [view setNeedsDisplay];
      }
    }
  }
}

- (void)selectAll:(id)sender
{
  if([self.items count] == 0)
    return;

  self.selectionStartItem = [self.items objectAtIndex:0];
  self.selectionStartIndex = 0;

  self.selectionEndItem = [self.items lastObject];
  self.selectionEndIndex = (int)[self.selectionEndItem.message length];

  NSNumber *indexPath;
  MVDiscussionMessageView *view;
  for(indexPath in self.visibleViews)
  {
    view = [self.visibleViews objectForKey:indexPath];
    if(view.item.type == kMVDiscussionMessageTypeText ||
       view.item.type == kMVDiscussionMessageTypeTweet)
    {
      [view.textRenderer setSelection:NSMakeRange(0, [view.item.message length])];
    }
  }
}

- (void)copy:(id)sender
{
  if([self hasSelection])
  {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pboard setData:[self.selectedString dataUsingEncoding:NSUTF8StringEncoding] forType:NSPasteboardTypeString];
  }
}

- (void)keyDown:(NSEvent *)event
{
  if([event keyCode] == 126)
  {
    // up
    [self selectUp];
  }
  else if([event keyCode] == 125)
  {
    // down
    [self selectDown];
  }
  else if([event isCharacter:' '])
  {
    // space
    [self toggleQuicklook];
  }
  else if([event keyCode] == 53)
  {
    // esc
    [super keyDown:event];
  }
  else if(!([QLPreviewPanel sharedPreviewPanelExists] &&
            [[QLPreviewPanel sharedPreviewPanel] isKeyWindow]))
  {
    if([self.delegate respondsToSelector:@selector(discussionView:keyDown:)])
      [self.delegate discussionView:self keyDown:event];
  }
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (BOOL)becomeFirstResponder
{
  [self setViewsDisplayAsFirstResponder:YES];
  return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
  [self resetSelection];
  if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible])
  {
    [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
  }
  [self setViewsDisplayAsFirstResponder:NO];
  return YES;
}

- (NSMenu*)menuForEvent:(NSEvent *)event
{
  if(self.hasSelection)
  {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Search with Google",
                                                                    @"DiscussionView Context Menu")
                                                  action:@selector(menuItemSearchGoogle:)
                                           keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
    [menu addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", @"TwUI Context Menu")
                                      action:@selector(copy:)
                               keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];
    return menu;
  }
  return nil;
}

#pragma mark -
#pragma mark Context Menu Item Actions

- (void)menuItemSearchGoogle:(NSMenuItem*)menuItem
{
  NSString *googleString = [NSString stringWithFormat:
                            @"http://www.google.com/search?q=%@",
                            [self.selectedString stringByAddingPercentEscapesUsingEncoding:
                             NSUTF8StringEncoding]];
  NSURL *googleUrl = [NSURL URLWithString:googleString];
  [[NSWorkspace sharedWorkspace] openURL:googleUrl];
}

#pragma mark -
#pragma mark Private Methods

- (MVDiscussionMessageView*)lastVisibleView
{
  CGRect visibleRect = self.visibleRect;
  NSNumber *indexPath;
  float minY = INTMAX_MAX;
  MVDiscussionMessageView *minView = nil;
  CGRect rect;
  for(indexPath in self.visibleViews)
  {
    rect = [self rectForIndexPath:indexPath.intValue];
    if(CGRectIntersection(visibleRect, rect).size.height >= rect.size.height - 6)
    {
      if(rect.origin.y < minY)
      {
        minY = rect.origin.y;
        minView = [self.visibleViews objectForKey:indexPath];
      }
    }
  }
  return minView;
}

- (void)setViewsDisplayAsFirstResponder:(BOOL)firstResponder
{
  MVDiscussionMessageView *view;
  for(view in [self.visibleViews allValues])
  {
    view.shouldDisplayAsFirstResponder = firstResponder;
  }
}

- (void)toggleQuicklook
{
  if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isKeyWindow])
  {
    [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
  }
  else
  {
    [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
  }
}

- (void)scrollToItem:(MVDiscussionMessageItem*)item animated:(BOOL)animated
{
  int indexPath = (int)[self.items indexOfObject:item];
  CGRect rect = [self rectForIndexPath:indexPath];
  rect = CGRectInset(rect, -5, -3);
  [self scrollRectToVisible:rect animated:animated];
}

- (BOOL)hasSelection
{
  if(!self.selectionStartItem || !self.selectionEndItem)
    return NO;
  // find out if item indexpath is between the two selected
  int fromIndexPath = (int)[self.items indexOfObject:self.selectionStartItem];
  int toIndexPath = (int)[self.items indexOfObject:self.selectionEndItem];
  int startIndex = self.selectionStartIndex;
  int endIndex = self.selectionEndIndex;
  if(fromIndexPath > toIndexPath || (fromIndexPath == toIndexPath && startIndex > endIndex))
  {
    int tmp = fromIndexPath;
    fromIndexPath = toIndexPath;
    toIndexPath = tmp;

    tmp = endIndex;
    endIndex = startIndex;
    startIndex = tmp;
  }
  return (fromIndexPath < toIndexPath ||
          (fromIndexPath == toIndexPath && startIndex < endIndex));
}

- (void)updateSelectedRangeForView:(MVDiscussionMessageView*)view
{
  NSRange range = NSMakeRange(0, 0);
  if([self hasSelection] && (view.item.type == kMVDiscussionMessageTypeText ||
                             view.item.type == kMVDiscussionMessageTypeTweet))
  {
    // find out if item indexpath is between the two selected
    int fromIndexPath = (int)[self.items indexOfObject:self.selectionStartItem];
    int toIndexPath = (int)[self.items indexOfObject:self.selectionEndItem];
    int startIndex = self.selectionStartIndex;
    int endIndex = self.selectionEndIndex;
    if(fromIndexPath > toIndexPath)
    {
      int tmp = fromIndexPath;
      fromIndexPath = toIndexPath;
      toIndexPath = tmp;

      tmp = endIndex;
      endIndex = startIndex;
      startIndex = tmp;
    }

    int indexPath = (int)[self.items indexOfObject:view.item];

    if(indexPath == fromIndexPath && indexPath == toIndexPath)
    {
      range = NSMakeRange(startIndex, endIndex - startIndex);
    }
    else if(indexPath == fromIndexPath)
    {
      range = NSMakeRange(startIndex, [view.item.message length] - startIndex);
    }
    else if(indexPath == toIndexPath)
    {
      range = NSMakeRange(0, endIndex);
    }
    else
    {
      BOOL selected = (indexPath > fromIndexPath && indexPath < toIndexPath);
      if(selected)
        range = NSMakeRange(0, [view.item.message length]);
    }
  }

  if(!NSEqualRanges(view.textRenderer.selectedRange, range))
  {
    [view.textRenderer setSelection:range];
  }
}

- (void)endLiveResize
{
  self.shouldProcessOffsets = YES;
  self.cachedExpectedHeight = -1;
  [self setNeedsLayout];
}

- (void)layoutViewsWithAdditionnalHeight:(int)additionnalHeight
{
  CGRect visible = [self visibleRect];
  visible.size.height += 400;
  visible.origin.y -= 110;

	// Example:
	// old:            0 1 2 3 4 5 6 7
	// new:                2 3 4 5 6 7 8 9
	// to remove:      0 1
	// to add:                         8 9

	NSArray *oldVisibleIndexPaths = [self.visibleViews allKeys];
	NSArray *newVisibleIndexPaths = [self indexPathsForRowsInRect:visible];

	NSMutableArray *indexPathsToRemove = [oldVisibleIndexPaths mutableCopy];
	[indexPathsToRemove removeObjectsInArray:newVisibleIndexPaths];

	NSMutableArray *indexPathsToAdd = [newVisibleIndexPaths mutableCopy];
	[indexPathsToAdd removeObjectsInArray:oldVisibleIndexPaths];

  MVDiscussionMessageView *view;
  NSNumber *indexPath;
  int i;

  // remove offscreen views
	for(indexPath in indexPathsToRemove)
  {
		view = [self.visibleViews objectForKey:indexPath];
    if(!view.item.animating)
    {
      [self enqueueReusableView:view];
      [view removeFromSuperview];
      [self.visibleViews removeObjectForKey:indexPath];
    }
	}

  // add new views
  NSMutableSet *animatedViews = [NSMutableSet set];
  CGRect frame;
	for(indexPath in indexPathsToAdd)
  {
		if(![self.visibleViews objectForKey:indexPath])
    {
      i = [indexPath intValue];
			view = [self createViewForIndexPath:i];
      [view removeAllAnimations];
      [self updateSelectedRangeForView:view];

      // set view in visibleViews before call rectForIndexPath because if we're in live resizing
      // we don't want to use cached size values
      [self.visibleViews setObject:view forKey:indexPath];

      frame = [self rectForIndexPath:i];
      if(view.item.animated)
      {
        if(!view.item.animating)
        {
          [animatedViews addObject:view];

          view.item.animating = YES;
          CGRect fromFrame = frame;
          CGPoint fromPoint = view.item.animatingFromPoint;
          fromFrame.origin.x = fromPoint.x;
          fromFrame.origin.y = fromPoint.y;
          view.frame = fromFrame;

          if(view.item.animationStyle == kMVDiscussionMessageAnimationStyleSentMessage)
          {
            view.drawsBubble = NO;
            [view redraw];
          }
        }
      }
      else
      {
        view.frame = frame;
      }
			view.layer.zPosition = [self zPositionForIndexPath:i andView:view];
			[view setNeedsDisplay];
			[self.animatedView addSubview:view];
		}
	}

  if(animatedViews.count > 0)
  {
    [CATransaction flush];
    MVDiscussionMessageView *view;
    for(view in animatedViews)
    {
      frame = [self rectForIndexPath:[self.items indexOfObject:view.item]];
      if(view.item.animationStyle == kMVDiscussionMessageAnimationStyleSentMessage)
      {
        self.ownMessagesAnimating++;
        if(self.contentOffset.y == 0)
        {
          if([self.delegate respondsToSelector:@selector(discussionViewShouldBeFront:)])
            [self.delegate discussionViewShouldBeFront:self];
        }
      }

      if(view.item.animationStyle == kMVDiscussionMessageAnimationStyleSentMessage)
      {
        [TUIView animateWithDuration:kMVDiscussionViewAnimationDuration animations:^{
          view.drawsBubble = YES;
          [view redraw];
          view.frame = frame;
        }];
        [self mv_performBlock:^{
          int i = [self.items indexOfObject:view.item];
          view.item.animated = view.item.animating = NO;
          if(i >= 0)
          {
            view.frame = [self rectForIndexPath:i];
            view.layer.zPosition = [self zPositionForIndexPath:i andView:view];
          }
          self.ownMessagesAnimating--;
          if(self.ownMessagesAnimating == 0)
          {
            if([self.delegate respondsToSelector:@selector(discussionViewShouldNotBeFront:)])
              [self.delegate discussionViewShouldNotBeFront:self];
          }
        } afterDelay:kMVDiscussionViewAnimationDuration];
      }
      else
      {
        [TUIView animateWithDuration:kMVDiscussionViewAnimationDuration animations:^{
          view.frame = frame;
        }];
        [self mv_performBlock:^{
          int i = [self.items indexOfObject:view.item];
          view.item.animated = view.item.animating = NO;
          if(i >= 0)
          {
            view.frame = [self rectForIndexPath:i];
            view.layer.zPosition = [self zPositionForIndexPath:i andView:view];
          }
          [view redraw];
        } afterDelay:kMVDiscussionViewAnimationDuration];
      }
    }
  }
}

- (NSArray *)indexPathsForRowsInRect:(CGRect)rect
{
  // search by dicotomy
  NSMutableArray *indexPaths = [NSMutableArray array];
  int count = (int)[self.items count];
  int d1 = 0;
  int d2 = count - 1;
  int i;
  rect = CGRectInset(rect, -1, -1);
  float midY = CGRectGetMidY(rect);
  BOOL found = NO;
  CGRect cellRect;

  if(count == 1)
  {
    i = 0;
    found = YES;
  }
  else
  {
    while(d1 <= d2 && !found)
    {
      i = d1 + (d2 - d1) / 2;
      cellRect = [self rectForIndexPath:i];
      if(CGRectIntersectsRect(cellRect, rect))
      {
        found = YES;
      }
      else if(CGRectGetMinY(cellRect) > midY)
      {
        d1 = d1 + MAX(((d2 - d1) / 2), 1);
      }
      else
      {
        d2 = d2 - MAX(((d2 - d1) / 2), 1);
      }
    }
  }

  if(found)
  {
    // find views before i
    BOOL cont = YES;
    int j = i - 1;
    while(cont && j >= 0)
    {
      cellRect = [self rectForIndexPath:j];
      if(CGRectIntersectsRect(cellRect, rect))
      {
        [indexPaths addObject:[NSNumber numberWithInt:j]];
        j--;
      }
      else
        cont = NO;
    }
    [indexPaths addObject:[NSNumber numberWithInt:i]];
    cont = YES;
    j = i + 1;
    while(cont && j < count)
    {
      cellRect = [self rectForIndexPath:j];
      if(CGRectIntersectsRect(cellRect, rect))
      {
        [indexPaths addObject:[NSNumber numberWithInt:j]];
        j++;
      }
      else
        cont = NO;
    }
  }

  // keep selectionStartItem View always around because if it gets removed
  // of the hierarchy, the mouseDragged event will not be forwarded
  if(self.selectionStartItem)
  {
    int index = (int)[self.items indexOfObject:self.selectionStartItem];
    if(index >= 0)
    {
      NSNumber *indexNumber = [NSNumber numberWithInt:index];
      if(![indexPaths containsObject:indexNumber]) {
        [indexPaths addObject:indexNumber];
      }
    }
  }

  return indexPaths;
}

- (CGSize)sizeForIndexPath:(int)indexPath
{
  MVDiscussionMessageItem *item = [self.items objectAtIndex:indexPath];
  CGSize size;
  if((![self.nsView inLiveResize] ||
      [self.visibleViews objectForKey:[NSNumber numberWithInt:indexPath]]))
  {
    size = [MVDiscussionMessageView sizeForItem:item
                              constrainedToWidth:self.bounds.size.width
                                    textRenderer:self.textRenderer
                                        inWindow:self.nsWindow];
    item.size = CGSizeMake(self.bounds.size.width, size.height);
  }
  return item.size;
}

- (CGRect)rectForIndexPath:(int)indexPath
{
  if(!(indexPath >= 0 && indexPath < self.items.count))
    return CGRectZero;
  MVDiscussionMessageItem *item = [self.items objectAtIndex:indexPath];
  CGSize size = [self sizeForIndexPath:indexPath];
  float offset = item.offset;
  return CGRectMake(0, offset, size.width, size.height);
}

- (void)enqueueReusableView:(MVDiscussionMessageView*)view
{
  [self.reusableViews addObject:view];
}

- (MVDiscussionMessageView*)dequeueReusableView
{
  MVDiscussionMessageView *view = [self.reusableViews lastObject];
  if(view)
    [self.reusableViews removeLastObject];
  else
  {
    view = [[MVDiscussionMessageView alloc] initWithFrame:CGRectZero];
    view.discussionView = self;
  }
  view.style = self.style;
  return view;
}

- (MVDiscussionMessageView*)createViewForIndexPath:(int)indexPath
{
  MVDiscussionMessageView *view = [self dequeueReusableView];
  MVDiscussionMessageItem *item = [self.items objectAtIndex:indexPath];
  view.shouldDisplayAsFirstResponder = (self.nsWindow.firstResponder == self);
  view.item = item;
  return view;
}

- (int)zPositionForIndexPath:(int)indexPath
                     andView:(MVDiscussionMessageView*)view
{
  return indexPath;
}

- (int)expectedHeight
{
  if(self.cachedExpectedHeight == -1)
  {
    int count = (int)self.items.count;
    int height = 0;
    for(int i=0;i<count;i++)
    {
      height += [self sizeForIndexPath:i].height;
      height += [MVDiscussionMessageView marginTopForItem:[self.items objectAtIndex:i]];
    }
    if(self.hasNotLoadedPreviousItems)
      height += kMVDiscussionViewLoadingMessagesHeight;
    if(self.hasNotLoadedNextItems)
      height += kMVDiscussionViewLoadingMessagesHeight;
    self.cachedExpectedHeight = height + 3;
  }
  return self.cachedExpectedHeight;
}

#pragma mark -
#pragma mark MVDiscussionMessageItemDelegate Methods

- (void)discussionMessageItemDidClearCachedSize:(MVDiscussionMessageItem*)item
{
  self.cachedExpectedHeight = -1;
  self.shouldProcessOffsets = YES;
  [self layoutSubviews:NO];
  int indexPathInt = [self.items indexOfObject:item];
  if(indexPathInt >= 0)
  {
    NSNumber *indexPath = [NSNumber numberWithInt:indexPathInt];
    MVDiscussionMessageView *view = [self.visibleViews objectForKey:indexPath];
    [view setNeedsDisplay];
  }
}

- (void)discussionMessageItemShouldRetryFileTransfer:(MVDiscussionMessageItem *)item
{
  if([self.delegate respondsToSelector:@selector(discussionView:shouldRetryFileTransfer:)])
    [self.delegate discussionView:self shouldRetryFileTransfer:item];
}

- (void)discussionMessageItemShouldRetrySendingMessage:(MVDiscussionMessageItem *)item
{
  if([self.delegate respondsToSelector:@selector(discussionView:shouldRetrySendingMessage:)])
    [self.delegate discussionView:self shouldRetrySendingMessage:item];
}

#pragma mark -
#pragma mark Quicklook Support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
  return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
  panel.delegate = self;
  panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
  panel.delegate = nil;
  panel.dataSource = nil;
}

#pragma mark -
#pragma mark QLPreviewPanelDataSource Methods

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
  return (self.selectedItem ? 1 : 0);
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	return self.selectedItem;
}

#pragma mark -
#pragma mark QLPreviewPanelDelegate Methods

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
  if([event type] == NSKeyDown)
  {
    [self keyDown:event];
    return YES;
  }
  return NO;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel
sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
  int indexPath = (int)[self.items indexOfObject:item];
  MVDiscussionMessageView *view = [self.visibleViews objectForKey:
                                                        [NSNumber numberWithInt:indexPath]];
  if(!view)
    return CGRectZero;

  CGRect rect = [view convertRect:view.quicklookRect toView:nil];
  if(!CGRectIntersectsRect(rect, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)))
     return CGRectZero;
  rect = [self.nsView convertRect:rect toView:nil];
  rect = [self.nsWindow convertRectToScreen:rect];
  return rect;
}

#pragma mark -
#pragma mark Drag And Drop support

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
  NSPasteboard *pboard = sender.draggingPasteboard;
  NSString *type = [pboard availableTypeFromArray:
                    [NSArray arrayWithObject:kMVDiscussionViewMessageDraggingType]];
  if(type)
  {
    NSString *value = [pboard stringForType:type];
    if(value.integerValue == [self hash])
      return NSDragOperationNone;
  }
  return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
  return [self draggingEntered:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  NSPasteboard *pboard = sender.draggingPasteboard;
  if([self.delegate respondsToSelector:@selector(discussionView:didDropPasteboard:)])
    return [self.delegate discussionView:self didDropPasteboard:pboard];
  return NO;
}

@end

@implementation _MVDiscussionContentView

@end