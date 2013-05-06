#import "MVChatViewController.h"
#import "MVChatConversationController.h"
#import "MVTabsView.h"
#import "MVBottomBarView.h"
#import "MVChatSectionView.h"
#import "MVRoundedTextView.h"

#define kMVBuddyListIdentifier @"kMVBuddyListIdentifier"

@interface MVChatViewController () <MVChatSectionViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;

@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) MVTabsView *tabsView;
@property (strong, readwrite) MVBottomBarView *bottomBarView;
@property (strong, readwrite) MVChatSectionView *chatSectionView;

@property (strong, readwrite) MVChatConversationController *chatConversationController;
@property (strong, readwrite) NSMutableDictionary *controllers;

- (void)displayController:(MVChatConversationController*)controller;
- (void)addTab:(XMPPJID*)jid
      animated:(BOOL)animated;

@end

@implementation MVChatViewController

@synthesize xmppStream = xmppStream_,
            view = view_,
            tabsView = tabsView_,
            bottomBarView = bottomBarView_,
            chatSectionView = chatSectionView_,
            chatConversationController = chatConversationController_,
            controllers = controllers_;

- (id)initWithStream:(XMPPStream*)xmppStream
{
  self = [super init];
  if(self)
  {
    xmppStream_ = xmppStream;
    [xmppStream_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    view_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    view_.backgroundColor = [TUIColor whiteColor];

    chatSectionView_ = [[MVChatSectionView alloc] initWithFrame:view_.bounds];
    chatSectionView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                        TUIViewAutoresizingFlexibleHeight;
    chatSectionView_.delegate = self;
    [chatSectionView_.tabsBarView addTab:@"Buddies" closable:NO sortable:NO online:NO
                              identifier:kMVBuddyListIdentifier animated:NO];
    [view_ addSubview:chatSectionView_];

    controllers_ = [NSMutableDictionary dictionary];
    
    chatConversationController_ = nil;
  }
  return self;
}

- (void)dealloc
{
  [xmppStream_ removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)newTab
{
  XMPPRoster *roster = (XMPPRoster*)[self.xmppStream moduleOfClass:[XMPPRoster class]];
  XMPPRosterMemoryStorage *rosterStorage = roster.xmppRosterStorage;
  
  XMPPJID *jid = [XMPPJID jidWithString:@"michaelvillar.com@gmail.com"];
  XMPPUserMemoryStorageObject *user = [rosterStorage userForJID:jid];
  if(user)
  {
    [self selectTab:jid animated:YES];
  }
}

#pragma mark Private Methods

- (void)displayController:(MVChatConversationController*)controller
{
  self.chatConversationController = controller;
  [self.chatSectionView displayDiscussionView:controller.discussionView
                                     textView:controller.textView];
}

- (void)addTab:(XMPPJID*)jid
      animated:(BOOL)animated
{
  [self.chatSectionView.tabsBarView addTab:jid.bare
                                  closable:YES
                                  sortable:YES
                                    online:YES
                                identifier:jid.bare
                                  animated:animated];
  
}

- (void)selectTab:(XMPPJID*)jid
         animated:(BOOL)animated
{
  [self addTab:jid animated:animated];
  [self.chatSectionView.tabsBarView setSelectedTab:jid.bare];
}

- (MVChatConversationController*)controllerForJid:(XMPPJID*)jid
{
  MVChatConversationController *controller = [self.controllers objectForKey:jid.bare];
  if(!controller) {
    MVDiscussionView *discussionView = nil;
    MVRoundedTextView *textView = nil;
    [self.chatSectionView getDiscussionView:&discussionView
                                   textView:&textView];
    controller = [[MVChatConversationController alloc] initWithStream:self.xmppStream
                                                                  jid:jid
                                                       discussionView:discussionView
                                                             textView:textView];
    [self.controllers setObject:controller forKey:jid.bare];
  }
  return controller;
}

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if ([message isChatMessageWithBody])
	{
    BOOL controllerExisted = [self.controllers objectForKey:message.from.bare] != nil;
    MVChatConversationController *controller = [self controllerForJid:message.from];
    if (!controllerExisted)
      [controller addMessage:message];

    if(![self.chatSectionView.tabsBarView hasTabForIdentifier:message.from])
    {
      [self addTab:message.from animated:YES];
    }
    
    [self selectTab:message.from animated:YES];
	}
}

#pragma mark MVChatSectionViewDelegate

- (void)chatSectionViewDidChangeTabs:(MVChatSectionView*)chatSectionView
{
  NSArray *identifiers = self.chatSectionView.tabsBarView.tabsIdentifiers;
  // check controllers that aren't in tabs anymore
  NSString *controllerKey;
  NSMutableArray *toRemoveControllersKey = [NSMutableArray array];
  for(controllerKey in self.controllers.allKeys)
  {
    if(![identifiers containsObject:controllerKey])
    {
      [toRemoveControllersKey addObject:controllerKey];
    }
  }
  [self.controllers removeObjectsForKeys:toRemoveControllersKey];
}

- (void)chatSectionView:(MVChatSectionView*)chatSectionView
  didChangeTabSelection:(NSObject*)identifier
{
  if(!identifier) {
    self.chatConversationController = nil;
    [self.chatSectionView displayDiscussionView:nil
                                       textView:nil];
    return;
  }
  NSString *stringIdentifier = (NSString*)identifier;
  if([stringIdentifier isEqualToString:kMVBuddyListIdentifier])
  {
    self.chatConversationController = nil;
    [self.chatSectionView displayDiscussionView:nil
                                       textView:nil];
    return;
  }
  XMPPJID *jid = [XMPPJID jidWithString:stringIdentifier];
  MVChatConversationController *controller = [self controllerForJid:jid];
    
  [self displayController:controller];
  [self.chatSectionView.nsWindow tui_makeFirstResponder:controller.textView];
}

- (void)chatSectionView:(MVChatSectionView*)chatSectionView
             sendString:(NSString*)string
{
  if([string length] <= 0)
    return;
  if(self.chatConversationController.discussionView == chatSectionView.discussionView)
    [self.chatConversationController sendMessage:string
                            animatedFromTextView:YES];
}
- (void)chatSectionViewTextViewTextDidChange:(MVChatSectionView*)chatSectionView
                              discussionView:(MVDiscussionView*)discussionView
{
  if(self.chatConversationController.discussionView == discussionView)
    [self.chatConversationController textViewDidChange];
}

@end
