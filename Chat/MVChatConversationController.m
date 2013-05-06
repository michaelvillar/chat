#import "MVChatConversationController.h"
#import "MVDiscussionView.h"
#import "MVDiscussionMessageItem.h"
#import "MVRoundedTextView.h"
#import "MVURLKit.h"
#import "NSMutableAttributedString+LinksDetection.h"
#import "MVDiscussionMessageItem.h"
#import "MVDiscussionViewController.h"

#define kMVChatConversationDateDisplayInterval 900
#define kMVComposingMaxDuration 30

@interface MVChatConversationController ()

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPJID *jid;
@property (strong, readwrite) MVDiscussionView *discussionView;
@property (strong, readwrite) MVRoundedTextView *textView;
@property (strong, readwrite) MVDiscussionViewController *discussionViewController;
@property (strong, readwrite) NSMutableDictionary *composingItems;
@property (readwrite) BOOL composing;
@property (strong, readwrite) NSTimer *composingTimer;

- (void)sendComposingMessage:(BOOL)composing;
- (void)removeWriteItemForJid:(XMPPJID*)jid;

@end

@implementation MVChatConversationController

@synthesize xmppStream                = xmppStream_,
            jid                       = jid_,
            discussionView            = discussionView_,
            textView                  = textView_,
            discussionViewController  = discussionViewController_,
            composingItems            = composingItems_,
            composing                 = composing_,
            composingTimer            = composingTimer_,
            identifier                = identifier_;

- (id)init
{
  self = [super init];
  if(self)
  {
    discussionView_ = nil;
    textView_ = nil;
    composing_ = NO;
    composingTimer_ = nil;
    identifier_ = nil;
  }
  return self;
}

- (id)initWithStream:(XMPPStream*)xmppStream
                 jid:(XMPPJID*)jid
      discussionView:(MVDiscussionView*)discussionView
            textView:(MVRoundedTextView*)textView
{
  self = [self init];
  if(self)
  {
    xmppStream_ = xmppStream;
    [xmppStream_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
    jid_ = jid;
    
    discussionView_ = discussionView;
    textView_ = textView;

    textView_.autocompletionEnabled = YES;
    textView_.autocompletionTriggerCharCount = 1;
    
    discussionViewController_ = [[MVDiscussionViewController alloc]
                                 initWithDiscussionView:discussionView
                                 xmppStream:xmppStream jid:jid];
    composingItems_ = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)dealloc
{
  [xmppStream_ removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)addMessage:(XMPPMessage*)message
{
  [self.discussionViewController addMessage:message animated:YES];
}

- (void)sendMessage:(NSString*)string
animatedFromTextView:(BOOL)animatedFromTextView
{
  self.composing = NO;
  if(self.composingTimer)
    [self.composingTimer invalidate], self.composingTimer = nil;
  
  string = [string stringByTrimmingCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@" "]];
  if(string.length <= 0)
    return;
  
  if(string.length > kMVMessageMaxChars)
  {
//    [self sendFileWithKey:@"message.txt"
//                     data:[string dataUsingEncoding:NSUTF8StringEncoding]];
    return;
  }
  
  XMPPMessage *message = [XMPPMessage elementWithName:@"message"];
	[message addAttributeWithName:@"type" stringValue:@"chat"];
	[message addAttributeWithName:@"to" stringValue:self.jid.full];
  [message addAttributeWithName:@"from" stringValue:self.xmppStream.myJID.full];
  
  NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
  [body setStringValue:string];
  [message addChild:body];
	
  NSXMLElement *stateElement = [NSXMLElement elementWithName:@"active"];
  [stateElement addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/chatstates"];
  [message addChild:stateElement];
	
	[self.xmppStream sendElement:message];
  
  [self.discussionViewController addMessage:message
                       animatedFromTextView:self.textView];
}

- (void)textViewDidChange
{
  if(self.textView.text.length <= 0)
    return;
  if(self.composingTimer)
    [self.composingTimer invalidate], self.composingTimer = nil;
  self.composingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                         target:self
                                                       selector:@selector(composingTimerAction)
                                                       userInfo:nil
                                                        repeats:NO];
  if(!self.composing)
  {
    self.composing = YES;
    [self sendComposingMessage:YES];
  }
}

#pragma mark Timer Actions

- (void)composingTimerAction
{
  self.composingTimer = nil;
  if(self.composing)
  {
    self.composing = NO;
    [self sendComposingMessage:NO];
  }
}

#pragma mark Private Methods

- (void)sendComposingMessage:(BOOL)composing
{
  XMPPMessage *message = [XMPPMessage elementWithName:@"message"];
	[message addAttributeWithName:@"type" stringValue:@"chat"];
	[message addAttributeWithName:@"to" stringValue:self.jid.full];
  [message addAttributeWithName:@"from" stringValue:self.xmppStream.myJID.full];
	
  NSXMLElement *stateElement = [NSXMLElement elementWithName:(composing ? @"composing" : @"active")];
  [stateElement addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/chatstates"];
  [message addChild:stateElement];
	
	[self.xmppStream sendElement:message];
}

- (void)removeWriteItemForJid:(XMPPJID*)jid
{
  MVDiscussionMessageItem *writingItem = [self.composingItems objectForKey:jid.bare];
  if(writingItem)
  {
    [self.composingItems removeObjectForKey:jid.bare];
    [self.discussionView removeDiscussionItem:writingItem];
    [self.discussionView layoutSubviews:YES];
  }
}

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
  if ([message.from isEqualToJID:self.jid
                         options:XMPPJIDCompareBare])
  {
    NSArray *nodes = message.children;
    NSXMLElement *node;
    NSString *state = nil;
    for (node in nodes) {
      NSArray *namespaces = [node namespaces];
      NSXMLNode *namespace;
      for (namespace in namespaces) {
        if(namespace && [[namespace stringValue] isEqualToString:@"http://jabber.org/protocol/chatstates"]) {
          state = [node name];
          break;
        }
      }
    }
    
    if(state)
    {
      BOOL composing = [state isEqualToString:@"cha:composing"];
      MVDiscussionMessageItem *writingItem = [self.composingItems objectForKey:message.from.bare];
      if(composing)
      {
        if(!writingItem)
        {
          XMPPvCardAvatarModule *module = (XMPPvCardAvatarModule*)[self.xmppStream moduleOfClass:
                                                                   [XMPPvCardAvatarModule class]];
          
          writingItem = [[MVDiscussionMessageItem alloc] init];
          writingItem.type = kMVDiscussionMessageTypeWriting;
          if(module)
          {
            NSData *photoData = [module photoDataForJID:message.from];
            if(photoData)
            {
              writingItem.avatar = [TUIImage imageWithData:photoData];
            }
          }
          
          writingItem.name = message.from.bare;
          writingItem.senderRepresentedObject = message.from;
          [self.discussionView addDiscussionItem:writingItem animated:YES];
          [self.discussionView layoutSubviews:YES];
          [self.composingItems setObject:writingItem forKey:message.from.bare];
        }
      }
      else if(writingItem)
      {
        [self removeWriteItemForJid:message.from];
      }    
    }
  
    if ([message isChatMessageWithBody])
    {
      [self addMessage:message];
    }
  }
}

@end
