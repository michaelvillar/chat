#import "MVXMPPClient.h"
#import "MVvCardFileDiskModuleStorage.h"

@interface MVXMPPClient ()

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPRoster *xmppRoster;
@property (strong, readwrite) XMPPvCardAvatarModule *xmppAvatarModule;
@property (strong, readwrite) NSString *email;
@property (strong, readwrite) NSString *password;

@end

@implementation MVXMPPClient

@synthesize xmppStream = xmppStream_,
            xmppRoster = xmppRoster_,
            xmppAvatarModule = xmppAvatarModule_,
            email = email_,
            password = password_,
            delegate = delegate_;

- (id)init
{
  self = [super init];
  if(self)
  {
    email_ = nil;
    password_ = nil;
    delegate_ = nil;
    
    xmppStream_ = [[XMPPStream alloc] init];
    XMPPRosterMemoryStorage *xmppRosterStorage = [[XMPPRosterMemoryStorage alloc] init];
    xmppRoster_ = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    [xmppRoster_ setAutoFetchRoster:YES];
    
    XMPPReconnect *xmppReconnect = [[XMPPReconnect alloc] init];
    
    MVvCardFileDiskModuleStorage *xmppvCardStorage = [[MVvCardFileDiskModuleStorage alloc] init];
    XMPPvCardTempModule *xmppvCardTempModule = [[XMPPvCardTempModule alloc]
                                                initWithvCardStorage:xmppvCardStorage];
    xmppAvatarModule_ = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    
    [xmppvCardTempModule activate:self.xmppStream];
    [xmppAvatarModule_ activate:self.xmppStream];
    [xmppRoster_ activate:self.xmppStream];
    [xmppReconnect activate:self.xmppStream];
    
    self.xmppStream.hostName = @"talk.google.com";
    self.xmppStream.hostPort = 5222;
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  return self;
}

- (void)connectWithEmail:(NSString*)email password:(NSString*)password
{
  self.email = email;
  self.password = password;
  
  [self disconnect];
  
  XMPPJID *jid = [XMPPJID jidWithString:self.email resource:kMVKeychainServiceName];
	self.xmppStream.myJID = jid;
  
  NSError *error = nil;
  BOOL success = [self.xmppStream connect:&error];
  if(!success && [self.delegate respondsToSelector:
                  @selector(mvXMPPClientDidFailToConnect:withError:)])
  {
    [self.delegate mvXMPPClientDidFailToConnect:self withError:error];
  }
}

- (void)connectIfDifferentWithEmail:(NSString*)email password:(NSString*)password
{
  if ([email isEqualToString:self.email] && [password isEqualToString:self.password])
    return;
  
  [self connectWithEmail:email password:password];
}

- (void)disconnect
{
  [self.xmppStream disconnect];
}

- (XMPPJID*)jid
{
  return self.xmppStream.myJID;
}

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
  // Allow expired certificates
  [settings setObject:[NSNumber numberWithBool:YES]
               forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
  
  // Allow self-signed certificates
  [settings setObject:[NSNumber numberWithBool:YES]
               forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
  
  // In fact, don't even validate the certificate chain
  [settings setObject:[NSNumber numberWithBool:NO]
               forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{}

- (void)xmppStreamDidConnect:(XMPPStream *)xmppStream
{
  NSError *error = nil;
  BOOL success;
  
  if(!self.xmppStream.isSecure)
  {
    success = [self.xmppStream connect:&error];
    if(!success && [self.delegate respondsToSelector:
                    @selector(mvXMPPClientDidFailToConnect:withError:)])
    {
      [self.delegate mvXMPPClientDidFailToConnect:self withError:error];
    }
  }
  else
  {
    success = [self.xmppStream authenticateWithPassword:self.password error:&error];
    if(!success && [self.delegate respondsToSelector:
                    @selector(mvXMPPClientDidFailToConnect:withError:)])
    {
      [self.delegate mvXMPPClientDidFailToConnect:self withError:error];
    }
  }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)xmppStream
{
  NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
  NSXMLElement *priority = [NSXMLElement elementWithName:@"priority"];
  [priority setStringValue:@"24"];
  [presence addChild:priority];
	[xmppStream sendElement:presence];
  
  if([self.delegate respondsToSelector:@selector(mvXMPPClientDidConnect:)])
  {
    [self.delegate mvXMPPClientDidConnect:self];
  }
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
  if([self.delegate respondsToSelector:@selector(mvXMPPClientDidFailToConnect:withError:)])
  {
    [self.delegate mvXMPPClientDidFailToConnect:self withError:nil];
  }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
  if([self.delegate respondsToSelector:@selector(mvXMPPClientDidDisconnect:withError:)])
  {
    [self.delegate mvXMPPClientDidDisconnect:self withError:nil];
  }
}

@end
