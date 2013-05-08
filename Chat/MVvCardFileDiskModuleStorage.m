#import "MVvCardFileDiskModuleStorage.h"
#import "MVURLKit.h"

@interface MVvCardFileDiskModuleStorage ()

@property (strong, readwrite) NSCache *vCards;

- (MVAsset*)assetFromJid:(XMPPJID*)jid;

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
  XMPPvCardTemp *vcard = [self.vCards objectForKey:jid.bare];
  if(vcard)
    return vcard;
  MVAsset *asset = [self assetFromJid:jid];
  if(asset.isExisting)
  {
    NSData *xmlData = [NSData dataWithContentsOfURL:asset.localURL];
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    if(document)
    {
      vcard = [XMPPvCardTemp vCardTempFromElement:document.rootElement];
      [self.vCards setObject:vcard forKey:jid.bare];
    }
  }
  return vcard;
}

- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  MVAsset *asset = [self assetFromJid:jid];
  NSXMLDocument *document = [[NSXMLDocument alloc] initWithRootElement:vCardTemp];
  NSData *xmlData = [document XMLDataWithOptions:NSXMLNodePrettyPrint];
  [xmlData writeToURL:asset.localURL atomically:YES];
  [self.vCards setObject:vCardTemp forKey:jid.bare];
}

- (BOOL)shouldFetchvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  XMPPvCardTemp *vCardTmp = [self vCardTempForJID:jid xmppStream:stream];
  return vCardTmp == nil;
}

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
  XMPPvCardTemp *vCardTmp = [self vCardTempForJID:jid xmppStream:stream];
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

#pragma mark Private Methods

- (MVAsset*)assetFromJid:(XMPPJID*)jid
{
  NSString *urlString = [NSString stringWithFormat:@"vcard://%@",jid.bare];
  NSURL *url = [NSURL URLWithString:urlString];
  return [[MVURLKit sharedInstance] assetForRemoteURL:url download:NO];
}

@end
