@interface MVHistoryConversation : NSObject

@property (strong, readonly) XMPPJID *jid;

- (id)initWithJid:(XMPPJID*)jid;
- (void)saveMessage:(XMPPMessage*)message;
- (NSOrderedSet*)messagesWithLimit:(NSUInteger)limit;
- (void)saveToDisk;

@end
