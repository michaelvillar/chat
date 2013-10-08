@class MVXMPPClient;

@protocol MVXMPPClientDelegate

- (void)mvXMPPClientDidConnect:(MVXMPPClient*)client;
- (void)mvXMPPClientDidFailToConnect:(MVXMPPClient*)client
                           withError:(NSError*)error;
- (void)mvXMPPClientDidDisconnect:(MVXMPPClient*)client
                        withError:(NSError*)error;

@end

@interface MVXMPPClient : NSObject

@property (strong, readonly) NSString *email;
@property (strong, nonatomic, readonly) XMPPJID *jid;
@property (strong, readonly) XMPPStream *xmppStream;
@property (strong, readonly) XMPPRoster *xmppRoster;
@property (strong, readonly) XMPPvCardAvatarModule *xmppAvatarModule;
@property (weak, readwrite) NSObject<MVXMPPClientDelegate> *delegate;

- (void)connectWithEmail:(NSString*)email password:(NSString*)password;
- (void)connectIfDifferentWithEmail:(NSString*)email password:(NSString*)password;
- (void)disconnect;

@end
