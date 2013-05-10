#import "MVController.h"

@class MVDiscussionView,
       MVRoundedTextView;

@interface MVChatConversationController : NSObject <MVController>

@property (strong, readonly) XMPPJID *jid;
@property (strong, readwrite) NSObject *identifier;

- (id)initWithStream:(XMPPStream*)xmppStream
                 jid:(XMPPJID*)jid;
- (void)addMessage:(XMPPMessage*)message;
- (void)sendMessage:(NSString*)string
animatedFromTextView:(BOOL)animatedFromTextView;

@end
