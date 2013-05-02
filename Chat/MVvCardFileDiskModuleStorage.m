#import "MVvCardFileDiskModuleStorage.h"

@interface MVvCardFileDiskModuleStorage ()

@property (strong, readwrite) NSCache *vCards;

@end

@implementation MVvCardFileDiskModuleStorage

@synthesize vCards          = vCards_;

- (BOOL)configureWithParent:(XMPPvCardTempModule *)aParent queue:(dispatch_queue_t)queue
{
  vCards_ = [[NSCache alloc] init];
  
  return YES;
}

- (XMPPvCardTemp *)vCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  return [self.vCards objectForKey:jid.bare];
}

- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  [self.vCards setObject:vCardTemp forKey:jid.bare];
  return;
}

- (BOOL)shouldFetchvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  return YES;
}

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  XMPPvCardTemp *vCardTmp = [self.vCards objectForKey:jid.bare];
  if(vCardTmp)
    return vCardTmp.photo;
  return nil;
}

- (NSString *)photoHashForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  return @"";
}

- (void)clearvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  [self.vCards removeObjectForKey:jid.bare];
}

@end
