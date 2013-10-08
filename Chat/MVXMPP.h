@protocol MVXMPPDelegate;

@interface MVXMPP : NSObject

@property (readonly, getter = hasEmptyConnectionInformation) BOOL emptyConnectionInformation;

+ (MVXMPP*)xmpp;
- (void)refreshFromPreferences;
- (void)addAccountWithEmail:(NSString*)email
                   password:(NSString*)password;
- (void)deleteAccountWithEmail:(NSString*)email;
- (BOOL)isEmailConnected:(NSString*)email;
- (NSArray*)rosters;
- (NSObject<XMPPUser>*)userForJID:(XMPPJID*)jid;
- (NSSet*)JIDsWithUserJID:(XMPPJID*)jid;
- (NSData*)photoDataForJID:(XMPPJID*)jid;
- (void)sendElement:(NSXMLElement*)element fromEmail:(NSString*)email;

- (void)addDelegate:(NSObject<MVXMPPDelegate>*)delegate;
- (void)removeDelegate:(NSObject<MVXMPPDelegate>*)delegate;

@end

@protocol MVXMPPDelegate <XMPPStreamDelegate,
                          XMPPRosterMemoryStorageDelegate>

@optional
- (void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule
              didReceivePhoto:(NSImage *)photo
                       forJID:(XMPPJID *)jid;
- (void)xmppDidConnect:(XMPPJID *)jid;
- (void)xmppDidFailToConnect:(XMPPJID *)jid;
- (void)xmppDidDisconnect:(XMPPJID *)jid;

@end