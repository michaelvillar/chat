#import "MVBuddiesManager.h"
#import "MVMulticastDelegate.h"

static MVBuddiesManager *instance;

@interface MVBuddiesManager ()

@property (strong, readwrite) XMPPRoster *xmppRoster;
@property (strong, readwrite) XMPPvCardAvatarModule *xmppAvatarModule;
@property (strong, readwrite) MVMulticastDelegate<MVBuddiesManagerDelegate> *multicastDelegate;

@property (strong, readwrite) NSCache *avatarsCache;
@property (strong, readwrite) NSMutableSet *jidsWithoutAvatar;

- (NSObject<XMPPUser>*)userForJid:(XMPPJID*)jid;

@end

@implementation MVBuddiesManager

@synthesize xmppStream = xmppStream_,
            xmppRoster = xmppRoster_,
            xmppAvatarModule = xmppAvatarModule_,
            multicastDelegate = multicastDelegate_,
            avatarsCache = avatarsCache_,
            jidsWithoutAvatar = jidsWithoutAvatar_;

+ (MVBuddiesManager*)sharedInstance
{
  if(!instance)
    instance = [[MVBuddiesManager alloc] init];
  return instance;
}

- (id)init
{
  self = [super init];
  if(self)
  {
    xmppStream_ = nil;
    xmppRoster_ = nil;
    xmppAvatarModule_ = nil;
    multicastDelegate_ = (MVMulticastDelegate<MVBuddiesManagerDelegate>*)
                         [[MVMulticastDelegate alloc] init];
    avatarsCache_ = [[NSCache alloc] init];
    jidsWithoutAvatar_ = [[NSMutableSet alloc] init];
  }
  return self;
}

- (void)setXmppStream:(XMPPStream *)xmppStream
{
  xmppStream_ = xmppStream;
  xmppRoster_ = (XMPPRoster*)[xmppStream moduleOfClass:[XMPPRoster class]];
  xmppAvatarModule_ = (XMPPvCardAvatarModule*)[xmppStream moduleOfClass:
                                               [XMPPvCardAvatarModule class]];
  
  [xmppStream_ autoAddDelegate:self
                 delegateQueue:dispatch_get_main_queue()
              toModulesOfClass:[XMPPvCardAvatarModule class]];
  [xmppRoster_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (NSArray*)buddies
{
  XMPPRosterMemoryStorage *storage = self.xmppRoster.xmppRosterStorage;
  NSArray *users = [storage unsortedUsers];
  return [users sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSObject<XMPPUser> *user1 = (NSObject<XMPPUser>*)obj1;
    NSObject<XMPPUser> *user2 = (NSObject<XMPPUser>*)obj2;
    NSString *user1Name = (user1.nickname ? user1.nickname : user1.jid.bare);
    NSString *user2Name = (user2.nickname ? user2.nickname : user2.jid.bare);
    return [user1Name.lowercaseString compare:user2Name.lowercaseString];
  }];
}

- (NSString*)nameForJid:(XMPPJID*)jid
{
  NSObject<XMPPUser> *user = [self userForJid:jid];
  if(user && user.nickname)
    return user.nickname;
  return jid.bare;
}

- (TUIImage*)avatarForJid:(XMPPJID*)jid
{
  TUIImage *avatar = [self.avatarsCache objectForKey:jid.bare];
  if(!avatar)
  {
    if([self.jidsWithoutAvatar containsObject:jid.bare])
      return nil;
    NSData *photoData = [self.xmppAvatarModule photoDataForJID:jid];
    if(photoData)
    {
      avatar = [TUIImage imageWithData:photoData];
      [self.avatarsCache setObject:avatar forKey:jid.bare];
    }
    else
      [self.jidsWithoutAvatar addObject:jid.bare];
  }
  return avatar;
}

- (BOOL)isJidOnline:(XMPPJID*)jid
{
  NSObject<XMPPUser> *user = [self userForJid:jid];
  return (user && user.isOnline);
}

#pragma mark Delegate

- (void)addDelegate:(NSObject<MVBuddiesManagerDelegate>*)delegate
{
  [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(NSObject<MVBuddiesManagerDelegate>*)delegate
{
  [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark Private Methods

- (NSObject<XMPPUser>*)userForJid:(XMPPJID*)jid
{
  XMPPRosterMemoryStorage *storage = self.xmppRoster.xmppRosterStorage;
  return [storage userForJID:jid];
}

#pragma mark XMPPRosterMemoryStorageDelegate Methods

- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
  [self.multicastDelegate buddiesManagerBuddiesDidChange:self];
}

- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender
    didAddResource:(XMPPResourceMemoryStorageObject *)resource
          withUser:(XMPPUserMemoryStorageObject *)user
{
  [self.multicastDelegate buddiesManager:self
                jidDidChangeOnlineStatus:user.jid];
}

- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender
 didUpdateResource:(XMPPResourceMemoryStorageObject *)resource
          withUser:(XMPPUserMemoryStorageObject *)user
{
  [self.multicastDelegate buddiesManager:self
                jidDidChangeOnlineStatus:user.jid];
}

- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender
 didRemoveResource:(XMPPResourceMemoryStorageObject *)resource
          withUser:(XMPPUserMemoryStorageObject *)user
{
  [self.multicastDelegate buddiesManager:self
                jidDidChangeOnlineStatus:user.jid];
}

#pragma mark XMPPvCardAvatarModuleDelegate Methods

- (void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule
              didReceivePhoto:(NSImage *)photo
                       forJID:(XMPPJID *)jid
{
  [self.multicastDelegate buddiesManager:self
                      jidDidChangeAvatar:jid];
}

@end
