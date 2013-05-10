#import "MVChatViewController.h"
#import "MVChatConversationController.h"
#import "MVRoundedTextView.h"
#import "MVBuddyListViewController.h"
#import "MVSwipeableView.h"

#define kMVBuddyListIdentifier @"kMVBuddyListIdentifier"

@interface MVChatViewController () <MVBuddyListViewControllerDelegate,
                                    MVSwipeableViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;

@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) MVSwipeableView *swipeableView;

@property (strong, readwrite) NSObject<MVController> *currentController;
@property (strong, readwrite) NSMutableDictionary *controllers;
@property (strong, readwrite) MVBuddyListViewController *buddyListViewController;

@property (readwrite) int connectionState;

- (void)displayController:(NSObject<MVController>*)controller;
- (NSObject<MVController>*)controllerForView:(TUIView *)view;

@end

@implementation MVChatViewController

@synthesize xmppStream = xmppStream_,
            view = view_,
            swipeableView = swipeableView_,
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
    
    controllers_ = [NSMutableDictionary dictionary];
    currentController_ = nil;
    
    view_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    view_.backgroundColor = [TUIColor blackColor];
    
    swipeableView_ = [[MVSwipeableView alloc] initWithFrame:view_.bounds];
    swipeableView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                      TUIViewAutoresizingFlexibleHeight;
    swipeableView_.delegate = self;
    [view_ addSubview:swipeableView_];

    buddyListViewController_ = [[MVBuddyListViewController alloc] initWithStream:self.xmppStream];
    buddyListViewController_.delegate = self;
    [swipeableView_ addSwipeableSubview:buddyListViewController_.view];
    
    currentController_ = buddyListViewController_;
    [currentController_ makeFirstResponder];
    
    [self updateWindowTitle];
      
    [self addObserver:self forKeyPath:@"connectionState" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [xmppStream_ removeDelegate:self delegateQueue:dispatch_get_main_queue()];
  [self removeObserver:self forKeyPath:@"connectionState"];
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

- (void)makeFirstResponder
{
  [self.currentController makeFirstResponder];
}

- (void)selectTab:(XMPPJID*)jid
         animated:(BOOL)animated
{
  MVChatConversationController *controller = [self controllerForJid:jid];
  [self displayController:controller];
}

#pragma mark KVO

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//  if(object == self && [keyPath isEqualToString:@"connectionState"]) {
//    self.chatSectionView.state = self.connectionState;
//  }
//  else {
//    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//  }
//}

#pragma mark Private Methods

- (void)updateWindowTitle
{
  if(!self.currentController)
    return;
  NSString *title = NSLocalizedString(@"Buddies", @"Window Title for Buddies");
  if(self.currentController != self.buddyListViewController)
  {
    MVChatConversationController *chatConversationController =
                          (MVChatConversationController*)self.currentController;
    title = chatConversationController.jid.bare;
  }
  self.view.nsWindow.title = title;
}

- (void)displayController:(NSObject<MVController>*)controller
{
  self.currentController = controller;
  [self.swipeableView addSwipeableSubview:controller.view];
  [self.swipeableView swipeToView:controller.view];
  [controller makeFirstResponder];
  [self updateWindowTitle];
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

- (MVChatConversationController*)controllerForJid:(XMPPJID*)jid
{
  MVChatConversationController *controller = [self.controllers objectForKey:jid.bare];
  if(!controller) {
    controller = [[MVChatConversationController alloc] initWithStream:self.xmppStream
                                                                  jid:jid];
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
  [self selectTab:user.jid animated:YES];
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
  }
}

@end
