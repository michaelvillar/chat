#import "MVXMPP.h"
#import "MVXMPPClient.h"
#import "MVMulticastDelegate.h"
#import "MVXMPPAccount.h"

static MVXMPP *xmpp;

@interface MVXMPP () <MVXMPPClientDelegate>

@property (strong, readwrite) NSMutableDictionary *accounts;
@property (strong, readwrite) MVMulticastDelegate<MVXMPPDelegate> *multicastDelegate;

@end

@implementation MVXMPP

@synthesize accounts = accounts_,
            multicastDelegate = multicastDelegate_;

+ (MVXMPP*)xmpp
{
  if(!xmpp)
    xmpp = [[MVXMPP alloc] init];
  return xmpp;
}

- (id)init
{
  self = [super init];
  if(self)
  {
    accounts_ = [NSMutableDictionary dictionary];
    multicastDelegate_ = (MVMulticastDelegate<MVXMPPDelegate>*)
                          [[MVMulticastDelegate alloc] init];
  }
  return self;
}

- (void)refreshFromPreferences
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSArray *gmailEmails = [defaults arrayForKey:kMVPreferencesGmailEmailsKey];
  NSMutableArray *accounts = [NSMutableArray array];
  if (gmailEmails) {
    for (NSString *email in gmailEmails) {
      MVXMPPAccount *account = [[MVXMPPAccount alloc] initWithEmail:email];
      [accounts addObject:account];
    }
  }
  [self refreshAccountsFromArray:accounts];
}

- (void)refreshAccountsFromArray:(NSArray*)accounts
{
  NSMutableDictionary *newAccounts = [NSMutableDictionary dictionary];
  for (MVXMPPAccount *account in accounts) {
    MVXMPPClient *client = [self.accounts objectForKey:account.email];
    if (!client) {
      client = [[MVXMPPClient alloc] init];
      [client.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
      [client.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
      client.delegate = self;
      NSLog(@"connect with %@ %@", account.email, account.password);
      [client connectWithEmail:account.email password:account.password];
    }
    else {
      [client connectIfDifferentWithEmail:account.email password:account.password];
    }
    [newAccounts setObject:client forKey:account.email];
  }
  for (MVXMPPClient *client in self.accounts.allValues) {
    if (![newAccounts.allValues containsObject:client])
      [client disconnect];
  }
  self.accounts = newAccounts;
}

- (void)addAccountWithEmail:(NSString*)email
                   password:(NSString*)password
{
  MVXMPPClient *client = [self.accounts objectForKey:email];
  if(!client)
  {
    client = [[MVXMPPClient alloc] init];
    [client.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [client.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    client.delegate = self;
    [self.accounts setObject:client forKey:email];
  }
  [client connectWithEmail:email password:password];
}

- (void)deleteAccountWithEmail:(NSString*)email
{
  MVXMPPClient *client = [self.accounts objectForKey:email];
  if(client)
  {
    client.delegate = nil;
    [client disconnect];
    [client.xmppStream removeDelegate:self];
    [client.xmppRoster removeDelegate:self];
    [self.accounts removeObjectForKey:client];
  }
}

- (NSArray*)rosters
{
  NSMutableArray *rosters = [NSMutableArray array];
  for(MVXMPPClient *client in self.accounts.allValues)
    [rosters addObject:client.xmppRoster];
  return rosters;
}

- (NSObject<XMPPUser>*)userForJID:(XMPPJID*)jid
{
  NSObject<XMPPUser>*user = nil;
  for(XMPPRoster *roster in self.rosters)
  {
    XMPPRosterMemoryStorage *storage = roster.xmppRosterStorage;
    user = [storage userForJID:jid];
    if(user)
      break;
  }
  return user;
}

- (NSSet*)JIDsWithUserJID:(XMPPJID*)jid
{
  NSMutableSet *jids = [NSMutableSet set];
  for(MVXMPPClient *client in self.accounts.allValues)
  {
    XMPPRoster *roster = client.xmppRoster;
    XMPPRosterMemoryStorage *storage = roster.xmppRosterStorage;
    if([storage userForJID:jid] && client.jid)
    {
      [jids addObject:client.jid];
    }
  }
  return jids;
}

- (NSData*)photoDataForJID:(XMPPJID*)jid
{
  NSData *data = nil;
  for(MVXMPPClient *client in self.accounts.allValues)
  {
    XMPPvCardAvatarModule *avatarModule = client.xmppAvatarModule;
    data = [avatarModule photoDataForJID:jid];
    if(data)
      break;
  }
  return data;
}

- (void)sendElement:(NSXMLElement*)element fromEmail:(NSString*)email
{
  MVXMPPClient *client = [self.accounts objectForKey:email];
  if(client)
  {
    [client.xmppStream sendElement:element];
  }
}

#pragma mark Delegate

- (void)addDelegate:(NSObject<MVXMPPDelegate>*)delegate
{
  [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(NSObject<MVXMPPDelegate>*)delegate
{
  [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark Properties

- (BOOL)hasEmptyConnectionInformation
{
  return self.accounts.count == 0;
}

#pragma mark MVXMPPClientDelegate Methods

- (void)mvXMPPClientDidConnect:(MVXMPPClient *)client
{
  
}

- (void)mvXMPPClientDidFailToConnect:(MVXMPPClient *)client withError:(NSError *)error
{
  
}

- (void)mvXMPPClientDidDisconnect:(MVXMPPClient *)client withError:(NSError *)error
{
  
}

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
  [self.multicastDelegate xmppStream:sender didReceiveMessage:message];
}

#pragma mark XMPPRosterDelegate

- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
  [self.multicastDelegate xmppRosterDidChange:sender];
}

- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender
    didAddResource:(XMPPResourceMemoryStorageObject *)resource
          withUser:(XMPPUserMemoryStorageObject *)user
{
  [self.multicastDelegate xmppRoster:sender didAddResource:resource withUser:user];
}

- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender
 didUpdateResource:(XMPPResourceMemoryStorageObject *)resource
          withUser:(XMPPUserMemoryStorageObject *)user
{
  [self.multicastDelegate xmppRoster:sender didUpdateResource:resource withUser:user];
}

- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender
 didRemoveResource:(XMPPResourceMemoryStorageObject *)resource
          withUser:(XMPPUserMemoryStorageObject *)user
{
  [self.multicastDelegate xmppRoster:sender didRemoveResource:resource withUser:user];
}

@end
