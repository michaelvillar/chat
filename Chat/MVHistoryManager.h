@interface MVHistoryManager : NSObject

+ (MVHistoryManager*)sharedInstance;
- (void)saveMessage:(XMPPMessage*)message forJid:(XMPPJID*)jid;

@end
