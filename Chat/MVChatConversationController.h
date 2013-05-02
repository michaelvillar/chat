#import <Foundation/Foundation.h>

@class MVDiscussionView,
       MVRoundedTextView;

@interface MVChatConversationController : NSObject

@property (strong, readwrite) NSObject *identifier;
@property (strong, readonly) MVDiscussionView *discussionView;
@property (strong, readonly) MVRoundedTextView *textView;

- (id)initWithStream:(XMPPStream*)xmppStream
                 jid:(XMPPJID*)jid
      discussionView:(MVDiscussionView*)discussionView
            textView:(MVRoundedTextView*)textView;
- (void)addMessage:(XMPPMessage*)message;
- (void)sendMessage:(NSString*)string
animatedFromTextView:(BOOL)animatedFromTextView;

@end
