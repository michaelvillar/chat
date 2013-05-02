#import <TwUI/TUIKit.h>

#define kMVChatSectionViewStateOnline 1
#define kMVChatSectionViewStateOffline 2
#define kMVChatSectionViewStateConnecting 3

@class MVBottomBarView,
       MVRoundedTextView,
       MVTabsView,
       MVDiscussionView,
       MVChatSectionView,
       MVDiscussionMessageItem;

@protocol MVChatSectionViewDelegate
@optional
- (void)chatSectionViewDidChangeTabs:(MVChatSectionView*)chatSectionView;
- (void)chatSectionView:(MVChatSectionView*)chatSectionView
 tabsViewDidChangeOrder:(MVTabsView*)tabsView;
- (void)chatSectionView:(MVChatSectionView*)chatSectionView
  didChangeTabSelection:(NSObject*)identifier;
- (void)chatSectionView:(MVChatSectionView*)chatSectionView
             sendString:(NSString*)string;
- (BOOL)chatSectionView:(MVChatSectionView*)chatSectionView
        pastePasteboard:(NSPasteboard*)pasteboard;
- (BOOL)chatSectionView:(MVChatSectionView*)chatSectionView
         dropPasteboard:(NSPasteboard*)pasteboard;
- (void)chatSectionViewShouldTryReconnection:(MVChatSectionView*)chatSectionView;
- (void)chatSectionViewShouldLoadPreviousItems:(MVChatSectionView*)chatSectionView
                                discussionView:(MVDiscussionView*)discussionView;
- (void)chatSectionViewShouldLoadNextItems:(MVChatSectionView*)chatSectionView
                            discussionView:(MVDiscussionView*)discussionView;
- (void)chatSectionViewDiscussionViewDidScroll:(MVChatSectionView*)chatSectionView
                                discussionView:(MVDiscussionView*)discussionView;
- (void)chatSectionViewTextViewTextDidChange:(MVChatSectionView*)chatSectionView
                              discussionView:(MVDiscussionView*)discussionView;
- (void)chatSectionView:(MVChatSectionView*)chatSectionView
   didClickNotification:(MVDiscussionMessageItem*)discussionItem;
- (void)chatSectionView:(MVChatSectionView*)chatSectionView
shouldRetryFileTransfer:(MVDiscussionMessageItem*)discussionItem;
- (void)chatSectionView:(MVChatSectionView*)chatSectionView
shouldRetrySendingMessage:(MVDiscussionMessageItem*)discussionItem;
@end


@interface MVChatSectionView : TUIView

@property (strong, readonly) MVBottomBarView *bottomBarView;
@property (strong, readonly) MVRoundedTextView *textView;
@property (strong, readonly) MVTabsView *tabsBarView;
@property (strong, readonly) MVDiscussionView *discussionView;
@property (readwrite, nonatomic) int state;
@property (weak, readwrite) NSObject <MVChatSectionViewDelegate> *delegate;

- (void)getDiscussionView:(MVDiscussionView**)discussionView
                 textView:(MVRoundedTextView**)textView;
- (void)displayDiscussionView:(MVDiscussionView*)discussionView
                     textView:(MVRoundedTextView*)textView;
- (void)forwardKeyDownEventToTextView:(NSEvent*)event;

@end
