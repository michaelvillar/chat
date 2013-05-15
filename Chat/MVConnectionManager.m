#import "MVConnectionManager.h"
#import "MVvCardFileDiskModuleStorage.h"
#import "EMKeychainItem.h"

static MVConnectionManager *instance;

@interface MVConnectionManager ()

@property (strong, readwrite) XMPPStream *xmppStream;
@property (readonly, nonatomic) NSString *email;
@property (readonly, nonatomic) NSString *password;

- (void)fireErrorNotification:(NSObject*)error;

@end

@implementation MVConnectionManager

@synthesize xmppStream = xmppStream_;

+ (MVConnectionManager*)sharedInstance
{
  if(!instance)
    instance = [[MVConnectionManager alloc] init];
  return instance;
}

- (id)init
{
  self = [super init];
  if(self)
  {
    self.xmppStream = [[XMPPStream alloc] init];
    XMPPRosterMemoryStorage *xmppRosterStorage = [[XMPPRosterMemoryStorage alloc] init];
    XMPPRoster *xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    [xmppRoster setAutoFetchRoster:YES];
    
    XMPPReconnect *xmppReconnect = [[XMPPReconnect alloc] init];
    
    MVvCardFileDiskModuleStorage *xmppvCardStorage = [[MVvCardFileDiskModuleStorage alloc] init];
    XMPPvCardTempModule *xmppvCardTempModule = [[XMPPvCardTempModule alloc]
                                                initWithvCardStorage:xmppvCardStorage];
    XMPPvCardAvatarModule *xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc]
                                                    initWithvCardTempModule:xmppvCardTempModule];
    
    [xmppvCardTempModule activate:self.xmppStream];
    [xmppvCardAvatarModule activate:self.xmppStream];
    [xmppRoster activate:self.xmppStream];
    [xmppReconnect activate:self.xmppStream];
    
    self.xmppStream.hostName = @"talk.google.com";
    self.xmppStream.hostPort = 5222;
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  return self;
}

- (void)signIn
{
  if(!(self.email && self.password))
  {
    NSError *error = [NSError errorWithDomain:@""
                                         code:-1
                                     userInfo:nil];
    [self fireErrorNotification:error];
    return;
  }
  
  [self.xmppStream disconnect];
  
  XMPPJID *jid = [XMPPJID jidWithString:self.email resource:kMVKeychainServiceName];
	self.xmppStream.myJID = jid;
  
  NSError *error = nil;
  BOOL success = [self.xmppStream connect:&error];
  if(!success)
    [self fireErrorNotification:error];
}

#pragma mark XMPPStreamDelegate

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
  NSLog(@"did secure");
}

- (void)xmppStreamDidConnect:(XMPPStream *)xmppStream
{
  NSError *error = nil;
  BOOL success;
  
  if(!self.xmppStream.isSecure)
  {
    success = [self.xmppStream connect:&error];
    if(!success)
      [self fireErrorNotification:error];
  }
  else
  {
    success = [self.xmppStream authenticateWithPassword:self.password error:&error];
    NSLog(@"error %@",error);
    if(!success)
      [self fireErrorNotification:error];
  }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)xmppStream
{
  NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
	[xmppStream sendElement:presence];
  [[NSNotificationCenter defaultCenter] postNotificationName:kMVConnectionSuccessNotification
                                                      object:self];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
  [self fireErrorNotification:error];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
  NSLog(@"did disconnect!");
}

#pragma mark Public Properties

- (BOOL)hasEmptyConnectionInformation
{
  return (!self.email || !self.password);
}

#pragma mark Private Methods

- (void)fireErrorNotification:(NSObject*)error
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kMVConnectionErrorNotification
                                                      object:self
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              error, @"error", nil]];
}

#pragma mark Private Properties

- (NSString*)email
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  return [defaults stringForKey:kMVPreferencesGmailEmailKey];
}

- (NSString*)password
{
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainServiceName
                                                                        withUsername:self.email];
  if(item)
    return item.password;
  return nil;
}

@end
