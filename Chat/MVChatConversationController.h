#import "MVController.h"

@class MVDiscussionView,
       MVRoundedTextView;

@interface MVChatConversationController : NSObject <MVController>

@property (strong, readonly) XMPPJID *jid;
@property (strong, readwrite) NSObject *identifier;
@property (readonly) NSUInteger unreadMessagesCount;

- (id)initWithJid:(XMPPJID*)jid;
- (id)initWithJid:(XMPPJID*)jid fromJid:(XMPPJID*)fromJid;
- (void)addMessage:(XMPPMessage*)message;
- (void)sendMessage:(NSString*)string
animatedFromTextView:(BOOL)animatedFromTextView;

@end
