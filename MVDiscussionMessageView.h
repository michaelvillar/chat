#import <TwUI/TUIKit.h>

@class MVDiscussionMessageItem,
       MVDiscussionView;

@interface MVDiscussionMessageView : TUIView

@property (strong, readwrite) MVDiscussionView *discussionView;
@property (strong, readonly) TUITextRenderer *textRenderer;
@property (strong, readwrite, nonatomic) MVDiscussionMessageItem *item;
@property (readwrite) BOOL drawsBubble;
@property (readwrite) int style;
@property (readwrite) int activeLinkIndex;
@property (readonly) CGRect quicklookRect;
@property (readonly) CGRect bubbleRect;
@property (readwrite, nonatomic) BOOL shouldDisplayAsFirstResponder;

+ (CGFloat)marginTopForItem:(MVDiscussionMessageItem*)item;
+ (CGSize)sizeForItem:(MVDiscussionMessageItem*)item
   constrainedToWidth:(float)width
         textRenderer:(TUITextRenderer*)textRenderer
             inWindow:(NSWindow*)window;
- (void)setBackgroundStartPercent:(float)start
                       endPercent:(float)end;

@end
