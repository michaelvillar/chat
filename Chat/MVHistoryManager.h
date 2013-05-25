@interface MVHistoryManager : NSObject

+ (MVHistoryManager*)sharedInstance;
- (void)saveMessage:(XMPPMessage*)message forJid:(XMPPJID*)jid;
- (NSOrderedSet*)messagesForJid:(XMPPJID*)jid
                          limit:(NSUInteger)limit;

@end
