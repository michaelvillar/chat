#import <Foundation/Foundation.h>

@class MVDiscussionView,
       MVRoundedTextView,
       MVAsset;

@interface MVDiscussionViewController : NSObject

@property (strong, readonly) MVDiscussionView *discussionView;

- (id)initWithDiscussionView:(MVDiscussionView*)discussionView
                         jid:(XMPPJID*)jid;

- (void)reset;
- (void)prependMessages:(NSArray*)messages;
- (void)addMessage:(XMPPMessage*)message
          animated:(BOOL)animated;
- (void)addMessage:(XMPPMessage*)message animatedFromTextView:(MVRoundedTextView*)textView;
- (void)addMessage:(XMPPMessage *)message
             asset:(MVAsset *)asset
              data:(NSData *)data;

@end
