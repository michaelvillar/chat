#import "MVChatViewController.h"
#import "MVChatConversationController.h"
#import "MVRoundedTextView.h"
#import "MVBuddyListViewController.h"
#import "MVSwipeableView.h"
#import "MVTabsView.h"

@interface MVChatViewController () <MVBuddyListViewControllerDelegate,
                                    MVSwipeableViewDelegate,
                                    MVTabsViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPRoster *xmppRoster;

@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) MVSwipeableView *swipeableView;
@property (strong, readwrite) MVTabsView *tabsView;

@property (strong, readwrite) NSObject<MVController> *currentController;
@property (strong, readwrite) NSMutableDictionary *controllers;
@property (strong, readwrite) MVBuddyListViewController *buddyListViewController;

@property (readwrite) int connectionState;

- (void)displayController:(NSObject<MVController>*)controller;
- (NSObject<MVController>*)controllerForView:(TUIView *)view;
- (NSObject<MVController>*)controllerForJid:(XMPPJID*)jid;

@end

@implementation MVChatViewController

@synthesize xmppStream = xmppStream_,
            xmppRoster = xmppRoster_,
            view = view_,
            swipeableView = swipeableView_,
            tabsView = tabsView_,
            currentController = currentController_,
            controllers = controllers_,
            buddyListViewController = buddyListViewController_,
            connectionState = connectionState_;

- (id)initWithStream:(XMPPStream*)xmppStream
{
  self = [super init];
  if(self)
  {
//    connectionState_ = kMVChatSectionViewStateOffline;

    xmppStream_ = xmppStream;
    [xmppStream_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
    xmppRoster_ = (XMPPRoster*)[xmppStream moduleOfClass:[XMPPRoster class]];
    
    controllers_ = [NSMutableDictionary dictionary];
    currentController_ = nil;
    
    view_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    view_.backgroundColor = [TUIColor blackColor];
    
    tabsView_ = [[MVTabsView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height,
                                                             self.view.frame.size.width, 23)];
    tabsView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                 TUIViewAutoresizingFlexibleBottomMargin;
    tabsView_.delegate = self;
    tabsView_.layer.zPosition = 10;
    [view_ addSubview:tabsView_];
    
    swipeableView_ = [[MVSwipeableView alloc] initWithFrame:view_.bounds];
    swipeableView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                      TUIViewAutoresizingFlexibleHeight;
    swipeableView_.delegate = self;
    swipeableView_.contentViewTopMargin = 23;
    [view_ addSubview:swipeableView_];

    buddyListViewController_ = [[MVBuddyListViewController alloc] initWithStream:self.xmppStream];
    buddyListViewController_.delegate = self;
    
    [self.tabsView addTab:[self titleForController:buddyListViewController_]
                 closable:NO
                 sortable:NO
                   online:NO
               identifier:buddyListViewController_
                  atIndex:1
                 animated:YES];
    [self.swipeableView insertSwipeableSubview:buddyListViewController_.view atIndex:1];
    [self displayController:buddyListViewController_];
    
    [self updateWindowTitle];
      
    [self addObserver:self forKeyPath:@"connectionState" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [xmppStream_ removeDelegate:self delegateQueue:dispatch_get_main_queue()];
  [self removeObserver:self forKeyPath:@"connectionState"];
  for(NSObject<MVController> *controller in self.controllers.allValues)
  {
    if(controller != buddyListViewController_)
      [controller removeObserver:self forKeyPath:@"unreadMessagesCount"];
  }
}

- (void)newTab
{
  XMPPRoster *roster = (XMPPRoster*)[self.xmppStream moduleOfClass:[XMPPRoster class]];
  XMPPRosterMemoryStorage *rosterStorage = roster.xmppRosterStorage;
  
  XMPPJID *jid = [XMPPJID jidWithString:@"michaelvillar.com@gmail.com"];
  XMPPUserMemoryStorageObject *user = [rosterStorage userForJID:jid];
  if(user)
  {
//    [self selectTab:jid animated:YES];
  }
}

- (void)makeFirstResponder
{
  [self.currentController makeFirstResponder];
}

- (NSUInteger)unreadMessagesCount
{
  NSUInteger count = 0;
  for(NSObject<MVController> *controller in self.controllers.allValues)
  {
    if(controller != self.buddyListViewController)
    {
      MVChatConversationController *chatConversationController =
                                    (MVChatConversationController*)controller;
      count += chatConversationController.unreadMessagesCount;
    }
  }
  return count;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if([self.controllers.allValues containsObject:object] &&
     [keyPath isEqualToString:@"unreadMessagesCount"]) {
    MVChatConversationController *controller = (MVChatConversationController*)object;
    [self.tabsView setGlowing:controller.unreadMessagesCount > 0
                   identifier:controller];
    [self willChangeValueForKey:@"unreadMessagesCount"];
    [self didChangeValueForKey:@"unreadMessagesCount"];
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark Private Methods

- (NSString*)titleForController:(NSObject<MVController>*)controller
{
  if(!controller)
    return @"";
  NSString *title = NSLocalizedString(@"Buddies", @"Window Title for Buddies");
  if(controller != self.buddyListViewController)
  {
    MVChatConversationController *chatConversationController = (MVChatConversationController*)controller;
    XMPPJID *jid = chatConversationController.jid;
    XMPPRosterMemoryStorage *storage = self.xmppRoster.xmppRosterStorage;
    XMPPUserMemoryStorageObject *user = [storage userForJID:jid];
    if(user && user.nickname)
    {
      title = user.nickname;
    }
    else
    {
      title = jid.bare;
    }
  }
  return title;
}

- (void)updateWindowTitle
{
  self.view.nsWindow.title = [self titleForController:self.currentController];
}

- (void)displayController:(NSObject<MVController>*)controller
{
  if(controller == self.currentController)
    return;
  
  self.currentController = controller;
  [self.swipeableView swipeToView:controller.view];
  [controller makeFirstResponder];
  [self updateWindowTitle];
  [self.tabsView setSelectedTab:controller];
}

- (NSObject<MVController>*)controllerForView:(TUIView *)view
{
  if(self.buddyListViewController.view == view)
    return self.buddyListViewController;
  for(MVChatConversationController *controller in self.controllers.allValues)
  {
    if(controller.view == view)
      return controller;
  }
  return nil;
}

- (NSObject<MVController>*)controllerForJid:(XMPPJID*)jid
{
  NSObject<MVController> *controller = [self.controllers objectForKey:jid.bare];
  if(!controller) {
    controller = [[MVChatConversationController alloc] initWithStream:self.xmppStream
                                                                  jid:jid];
    [controller addObserver:self forKeyPath:@"unreadMessagesCount" options:0 context:NULL];
    [self.controllers setObject:controller forKey:jid.bare];
  }
  if(![self.tabsView hasTabForIdentifier:controller])
  {
    [self.tabsView addTab:[self titleForController:controller]
                 closable:YES
                 sortable:YES
                   online:YES
               identifier:controller
                  atIndex:1
                 animated:YES];
    [self.swipeableView insertSwipeableSubview:controller.view atIndex:1];
  }
  return controller;
}

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if ([message isChatMessageWithBody])
	{
    BOOL controllerExisted = [self.controllers objectForKey:message.from.bare] != nil;
    MVChatConversationController *controller = (MVChatConversationController*)
                                                [self controllerForJid:message.from];
    if (!controllerExisted)
      [controller addMessage:message];
	}
}

- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
//  self.connectionState = kMVChatSectionViewStateConnecting;
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
//  self.connectionState = kMVChatSectionViewStateOnline;
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
//  self.connectionState = kMVChatSectionViewStateOffline;
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
//  self.connectionState = kMVChatSectionViewStateOffline;
}

#pragma mark MVBuddyListViewControllerDelegate Methods

- (void)buddyListViewController:(MVBuddyListViewController*)controller
                  didClickBuddy:(NSObject<XMPPUser>*)user
{
  [self displayController:[self controllerForJid:user.jid]];
}

#pragma mark MVSwipeableViewDelegate Methods

- (void)swipeableView:(MVSwipeableView *)swipeableView didSwipeToView:(TUIView *)view
{
  NSObject<MVController> *controller = [self controllerForView:view];
  if(controller)
  {
    self.currentController = controller;
    [controller makeFirstResponder];
    [self updateWindowTitle];
    [self.tabsView setSelectedTab:controller];
  }
}

#pragma mark MVTabsViewDelegate

- (void)tabsViewDidChangeTabs:(MVTabsView *)tabsView
{
  for(NSString *bareJid in self.controllers.allKeys)
  {
    NSObject<MVController> *controller = [self.controllers objectForKey:bareJid];
    if(![tabsView.tabsIdentifiers containsObject:controller])
    {
      [controller removeObserver:self forKeyPath:@"unreadMessagesCount"];
      [self.controllers removeObjectForKey:bareJid];
      [self.swipeableView removeSwipeableSubview:controller.view];
    }
  }
  
  [TUIView animateWithDuration:0.4 animations:^{
    CGRect frame = self.tabsView.frame;
    if([self.tabsView countTabs] > 0)
    {
      frame.origin.y = self.view.frame.size.height - 23;
    }
    else
    {
      frame.origin.y = self.view.frame.size.height;
    }
    self.tabsView.frame = frame;
  }];
}

- (void)tabsViewDidChangeSelection:(MVTabsView*)tabsView
{
  NSObject<MVController> *controller = (NSObject<MVController> *)tabsView.selectedTab;
  if(controller)
    [self displayController:controller];
}

- (void)tabsViewDidChangeOrder:(MVTabsView*)tabsView
{
  NSMutableArray *viewsOrder = [NSMutableArray array];
  for(NSObject<MVController>* controller in tabsView.tabsIdentifiers)
  {
    [viewsOrder addObject:controller.view];
  }
  [self.swipeableView setSwipeableSubviewsOrder:viewsOrder];
}

@end
