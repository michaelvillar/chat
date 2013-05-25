#import "MVChatConversationController.h"
#import "MVDiscussionView.h"
#import "MVDiscussionMessageItem.h"
#import "MVRoundedTextView.h"
#import "MVURLKit.h"
#import "NSMutableAttributedString+LinksDetection.h"
#import "MVDiscussionMessageItem.h"
#import "MVDiscussionViewController.h"
#import "MVChatSectionView.h"
#import "NSPasteboard+EnumerateKeysAndDatas.h"
#import "MVHistoryManager.h"

#define kMVChatConversationDateDisplayInterval 900
#define kMVComposingMaxDuration 30

@interface MVChatConversationController () <MVChatSectionViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPJID *jid;
@property (strong, readwrite) MVChatSectionView *chatSectionView;
@property (strong, readwrite) MVDiscussionView *discussionView;
@property (strong, readwrite) MVRoundedTextView *textView;
@property (strong, readwrite) MVDiscussionViewController *discussionViewController;
@property (strong, readwrite) NSMutableDictionary *composingItems;
@property (readwrite) BOOL composing;
@property (strong, readwrite) NSTimer *composingTimer;
@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) NSMutableOrderedSet *unreadMessages;
@property (strong, readwrite) NSMutableSet *uploadingMessages;

- (void)sendComposingMessage:(BOOL)composing;
- (void)removeWriteItemForJid:(XMPPJID*)jid;
- (BOOL)isViewVisibleAndApplicationActive;
- (void)updateUnreadMessages;

@end

@implementation MVChatConversationController

@synthesize xmppStream                = xmppStream_,
            jid                       = jid_,
            chatSectionView           = chatSectionView_,
            discussionView            = discussionView_,
            textView                  = textView_,
            discussionViewController  = discussionViewController_,
            composingItems            = composingItems_,
            composing                 = composing_,
            composingTimer            = composingTimer_,
            view                      = view_,
            unreadMessages            = unreadMessages_,
            uploadingMessages         = uploadingMessages_,
            identifier                = identifier_;

- (id)init
{
  self = [super init];
  if(self)
  {
    chatSectionView_ = nil;
    discussionView_ = nil;
    textView_ = nil;
    composing_ = NO;
    composingTimer_ = nil;
    unreadMessages_ = [NSMutableOrderedSet orderedSet];
    uploadingMessages_ = [NSMutableSet set];
    identifier_ = nil;
  }
  return self;
}

- (id)initWithStream:(XMPPStream*)xmppStream
                 jid:(XMPPJID*)jid
{
  self = [self init];
  if(self)
  {
    xmppStream_ = xmppStream;
    [xmppStream_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
    jid_ = jid;
    
    chatSectionView_ = [[MVChatSectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    chatSectionView_.state = kMVChatSectionViewStateOnline;
    chatSectionView_.delegate = self;
    
    view_ = chatSectionView_;
    discussionView_ = chatSectionView_.discussionView;
    textView_ = chatSectionView_.textView;

    textView_.autocompletionEnabled = YES;
    textView_.autocompletionTriggerCharCount = 1;
    
    discussionViewController_ = [[MVDiscussionViewController alloc]
                                 initWithDiscussionView:discussionView_
                                 xmppStream:xmppStream jid:jid];
    composingItems_ = [NSMutableDictionary dictionary];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidBecomeActive:)
               name:NSApplicationDidBecomeActiveNotification object:NSApp];
    
    NSOrderedSet *messages = [[MVHistoryManager sharedInstance] messagesForJid:self.jid
                                                                         limit:25];
    [discussionViewController_ prependMessages:messages.array];
  }
  return self;
}

- (void)dealloc
{
  [xmppStream_ removeDelegate:self delegateQueue:dispatch_get_main_queue()];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)makeFirstResponder
{
  [self updateUnreadMessages];
  [self.textView makeFirstResponder];
}

- (NSUInteger)unreadMessagesCount
{
  return self.unreadMessages.count;
}

- (void)addMessage:(XMPPMessage*)message
{
  [self.discussionViewController addMessage:message animated:YES];
  [[MVHistoryManager sharedInstance] saveMessage:message forJid:self.jid];
  
  BOOL scrollAtBottom = (self.discussionView.contentOffset.y > -10);
  if(!(scrollAtBottom && self.isViewVisibleAndApplicationActive))
  {
    [self willChangeValueForKey:@"unreadMessagesCount"];
    [self.unreadMessages addObject:message];
    [self didChangeValueForKey:@"unreadMessagesCount"];
  }
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
    [self sendFileWithKey:@"message.txt"
                     data:[string dataUsingEncoding:NSUTF8StringEncoding]];
    return;
  }
  
  XMPPMessage *message = [XMPPMessage messageWithType:@"chat"];
	[message addAttributeWithName:@"to" stringValue:self.jid.full];
  [message addAttributeWithName:@"from" stringValue:self.xmppStream.myJID.full];
  
  NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
  [body setStringValue:string];
  [message addChild:body];
	
  NSXMLElement *stateElement = [NSXMLElement elementWithName:@"active"];
  [stateElement addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/chatstates"];
  [message addChild:stateElement];
	
	[self.xmppStream sendElement:message];
  [[MVHistoryManager sharedInstance] saveMessage:message forJid:self.jid];
  
  [self.discussionViewController addMessage:message
                       animatedFromTextView:self.textView];
  
  if(self.unreadMessages.count > 0)
  {
    [self willChangeValueForKey:@"unreadMessagesCount"];
    [self.unreadMessages removeAllObjects];
    [self didChangeValueForKey:@"unreadMessagesCount"];
  }
}

- (void)sendFileWithKey:(NSString*)key
                   data:(NSData*)data
{
  // TODO : upload files sequentially to keep message order intact
  MVURLKit *urlKit = [MVURLKit sharedInstance];
  MVAsset *asset = [urlKit uploadFileWithKey:key data:data];
  [asset addObserver:self
          forKeyPath:@"uploadFinished"
             options:0
             context:NULL];
  
  XMPPMessage *message = [XMPPMessage messageWithType:@"chat"];
	[message addAttributeWithName:@"to" stringValue:self.jid.full];
  [message addAttributeWithName:@"from" stringValue:self.xmppStream.myJID.full];
  
  NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
  [body setStringValue:@""];
  [message addChild:body];
	  
  [self.uploadingMessages addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     message, @"message",
                                     body, @"body",
                                     asset, @"asset", nil]];
  
  [self.discussionViewController addMessage:message
                                      asset:asset
                                       data:data];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([object isKindOfClass:[MVAsset class]])
  {
    MVAsset *asset = (MVAsset*)object;
    if([keyPath isEqualToString:@"uploadFinished"])
    {
      if(asset.uploadFinished)
      {
        BOOL found = NO;
        NSDictionary *dic;
        for(dic in self.uploadingMessages)
        {
          if([dic objectForKey:@"asset"] == asset)
          {
            found = YES;
            break;
          }
        }
        
        if(found)
        {
          [asset removeObserver:self forKeyPath:@"uploadFinished"];

          XMPPMessage *message = [dic objectForKey:@"message"];
          NSXMLElement *body = [dic objectForKey:@"body"];
          
          [body setStringValue:asset.fileUploadRemoteURL.absoluteString];
          
          [self.xmppStream sendElement:message];
          [[MVHistoryManager sharedInstance] saveMessage:message forJid:self.jid];
          
          [self.uploadingMessages removeObject:dic];
        }
      }
    }
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark Window Notifications

- (void)applicationDidBecomeActive:(NSNotification*)notification
{
  [self updateUnreadMessages];
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

- (BOOL)isViewVisibleAndApplicationActive
{
  if(![NSApp isActive] || !self.discussionView.nsView)
    return NO;
  // check if the view in within the window visible rect
  CGSize windowVisibleSize = ((NSView*)(self.discussionView.nsWindow.contentView)).frame.size;
  CGRect viewFrame = [self.discussionView convertRect:self.discussionView.bounds toView:nil];
  viewFrame = [self.discussionView.nsView convertRect:viewFrame toView:nil];
  CGRect intersection = CGRectIntersection(CGRectMake(0, 0,
                                                      windowVisibleSize.width,
                                                      windowVisibleSize.height),
                                           viewFrame);
  if(abs(intersection.size.width - viewFrame.size.width) > 10)
    return NO;
  return YES;
}

- (void)updateUnreadMessages
{
  if(!self.isViewVisibleAndApplicationActive)
    return;
  MVDiscussionMessageItem *item = self.discussionView.lastVisibleItemHavingMessage;
  if(item)
  {
    XMPPMessage *message = (XMPPMessage*)(item.representedObject);
    if([self.unreadMessages containsObject:message])
    {
      NSUInteger index = [self.unreadMessages indexOfObject:message];
      NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, index + 1)];
      
      [self willChangeValueForKey:@"unreadMessagesCount"];
      [self.unreadMessages removeObjectsAtIndexes:indexSet];
      [self didChangeValueForKey:@"unreadMessagesCount"];
    }
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

#pragma mark MVChatSectionViewDelegate Methods

- (BOOL)chatSectionView:(MVChatSectionView*)chatSectionView
             sendString:(NSString*)string
{
  if([string length] <= 0)
    return NO;
  [self sendMessage:string animatedFromTextView:YES];
  return YES;
}

- (void)chatSectionViewTextViewTextDidChange:(MVChatSectionView*)chatSectionView
                              discussionView:(MVDiscussionView*)discussionView
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

- (void)chatSectionViewDiscussionViewDidScroll:(MVChatSectionView*)chatSectionView
                                discussionView:(MVDiscussionView*)discussionView
{
  [self updateUnreadMessages];
}

- (BOOL)chatSectionView:(MVChatSectionView*)chatSectionView
        pastePasteboard:(NSPasteboard*)pasteboard
{
  if([pasteboard mv_hasDetectedFile])
  {
    if(chatSectionView.textView.text.length > 0)
    {
      [self sendMessage:chatSectionView.textView.text animatedFromTextView:NO];
      chatSectionView.textView.text = @"";
    }
    
    __block BOOL found = NO;
    [pasteboard mv_enumerateKeysAndDatas:^(NSString *key, NSData *data)
     {
       found = YES;
       dispatch_async(dispatch_get_main_queue(), ^{
         [self sendFileWithKey:key data:data];
       });
     }];
    return found;
  }
  return NO;
}

- (BOOL)chatSectionView:(MVChatSectionView*)chatSectionView
         dropPasteboard:(NSPasteboard*)pasteboard
{
  return [self chatSectionView:chatSectionView pastePasteboard:pasteboard];
}

@end
