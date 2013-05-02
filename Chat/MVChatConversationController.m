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

@end

@implementation MVChatConversationController

@synthesize xmppStream                = xmppStream_,
            jid                       = jid_,
            discussionView            = discussionView_,
            textView                  = textView_,
            discussionViewController  = discussionViewController_,
            identifier                = identifier_;

- (id)init
{
  self = [super init];
  if(self)
  {
    discussionView_ = nil;
    textView_ = nil;
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
	
//	if(state != nil) {
//		NSXMLElement *stateElement = [NSXMLElement elementWithName:state];
//		[stateElement addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/chatstates"];
//		[message addChild:stateElement];
//	}
	
	[self.xmppStream sendElement:message];
  
  [self.discussionViewController addMessage:message
                       animatedFromTextView:self.textView];
}

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if ([message.from isEqualToJID:self.jid
                         options:XMPPJIDCompareBare] &&
      [message isChatMessageWithBody])
	{
    [self addMessage:message];
  }
}

@end
