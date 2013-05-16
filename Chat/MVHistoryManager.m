#import "MVHistoryManager.h"
#import "MVHistoryConversation.h"

static MVHistoryManager *sharedInstance;

@interface MVHistoryManager ()

@property (strong, readwrite) NSMutableDictionary *conversations;

- (MVHistoryConversation*)conversationForJid:(XMPPJID*)jid;

@end

@implementation MVHistoryManager

@synthesize conversations = conversations_;

+ (MVHistoryManager*)sharedInstance
{
  if(!sharedInstance)
    sharedInstance = [[MVHistoryManager alloc] init];
  return sharedInstance;
}

- (id)init
{
  self = [super init];
  if(self)
  {
    conversations_ = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)saveMessage:(XMPPMessage*)message forJid:(XMPPJID*)jid
{
  MVHistoryConversation *conversation = [self conversationForJid:jid];
  [conversation saveMessage:message];
}

#pragma mark Private Methods

- (MVHistoryConversation*)conversationForJid:(XMPPJID*)jid
{
  MVHistoryConversation *conversation = [self.conversations objectForKey:jid.bare];
  if(!conversation)
  {
    conversation = [[MVHistoryConversation alloc] initWithJid:jid];
    [self.conversations setObject:conversation forKey:jid.bare];
  }
  return conversation;
}

@end
