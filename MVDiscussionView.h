#import <TwUI/TUIKit.h>
#import <QuickLook/QuickLook.h>
#import <Quartz/Quartz.h>

#define kMVDiscussionViewStyleBlueGradient 1
#define kMVDiscussionViewStyleTransparent 2
#define kMVDiscussionViewMessageDraggingType @"kMVDiscussionViewMessageDraggingType"

@class MVDiscussionView;
@class MVDiscussionMessageItem;
@class MVRoundedTextView;

@protocol MVDiscussionViewDelegate <TUIScrollViewDelegate>
@optional
- (void)discussionViewShouldBeFront:(MVDiscussionView*)discussionView;
- (void)discussionViewShouldNotBeFront:(MVDiscussionView*)discussionView;
- (void)discussionView:(MVDiscussionView*)discussionView
               keyDown:(NSEvent*)event;
- (void)discussionViewShouldGiveFocusToTextField:(MVDiscussionView*)discussionView;
- (void)discussionViewShouldLoadPreviousItems:(MVDiscussionView*)discussionView;
- (void)discussionViewShouldLoadNextItems:(MVDiscussionView*)discussionView;
- (BOOL)discussionView:(MVDiscussionView *)discussionView
     didDropPasteboard:(NSPasteboard*)pboard;
- (void)discussionView:(MVDiscussionView *)discussionView
  didClickNotification:(MVDiscussionMessageItem*)discussionItem;
- (void)discussionView:(MVDiscussionView *)discussionView
shouldRetryFileTransfer:(MVDiscussionMessageItem*)discussionItem;
- (void)discussionView:(MVDiscussionView *)discussionView
shouldRetrySendingMessage:(MVDiscussionMessageItem*)discussionItem;
@end

@interface MVDiscussionView : TUIScrollView

@property (unsafe_unretained, readwrite, nonatomic) NSObject <MVDiscussionViewDelegate> *delegate;
@property (readwrite) int style;
@property (readwrite) BOOL hasNotLoadedPreviousItems;
@property (readwrite) BOOL hasNotLoadedNextItems;
@property (readonly, nonatomic) int countItems;
@property (readwrite) BOOL allowsBlankslate;
@property (readonly, nonatomic) MVDiscussionMessageItem *lastVisibleItemHavingMessage;
@property (nonatomic, readonly) NSString *selectedString;

- (void)removeAllDiscussionItems;
- (void)insertDiscussionItemAtTop:(MVDiscussionMessageItem*)discussionItem;
- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem;
- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
                 animated:(BOOL)animated;
- (void)addDiscussionItem:(MVDiscussionMessageItem*)discussionItem
      animateFromTextView:(MVRoundedTextView*)textView;
- (void)removeDiscussionItem:(MVDiscussionMessageItem*)discussionItem;
- (MVDiscussionMessageItem*)discussionItemAtIndex:(int)index;
- (MVDiscussionMessageItem*)discussionItemForRepresentedObject:(NSObject*)representedObject;
- (NSOrderedSet*)discussionItemsForRepresentedObject:(NSObject*)representedObject;
- (void)layoutSubviews:(BOOL)animated;
- (void)resetSelection;
- (void)selectUp;
- (void)selectDown;
- (void)resetSelectedItem;
- (void)scrollToCenterItem:(MVDiscussionMessageItem*)discussionItem animated:(BOOL)animated;

@end
