#import <Foundation/Foundation.h>

@class MVDiscussionView,
       MVRoundedTextView,
       MVAsset;

@interface MVDiscussionViewController : NSObject

@property (strong, readonly) MVDiscussionView *discussionView;

- (id)initWithDiscussionView:(MVDiscussionView*)discussionView
                  xmppStream:(XMPPStream*)xmppStream
                         jid:(XMPPJID*)jid;

- (void)reset;
- (void)addMessage:(XMPPMessage*)message
          animated:(BOOL)animated;
- (void)addMessage:(XMPPMessage*)message animatedFromTextView:(MVRoundedTextView*)textView;

@end
