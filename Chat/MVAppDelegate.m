#import "MVAppDelegate.h"
#import "MVChatViewController.h"
#import "MVvCardFileDiskModuleStorage.h"
#import "MVAccountController.h"
#import "MVCloudAppAccountController.h"
#import "MVConnectionManager.h"
#import "MVNSContentView.h"
#import "MVUploadAuthorization.h"
#import "MVURLKit.h"
#import "MVBuddiesManager.h"
#import "EMKeychainItem.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

@interface MVAppDelegate ()

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) MVChatViewController *chatViewController;
@property (strong, readwrite, nonatomic) MVAccountController *accountController;
@property (strong, readwrite, nonatomic) MVCloudAppAccountController *cloudAppAccountController;

@end

@implementation MVAppDelegate

@synthesize xmppStream = xmppStream_,
            chatViewController = chatViewController_,
            accountController = accountController_,
            cloudAppAccountController = cloudAppAccountController_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  MVConnectionManager *connectionManager = [MVConnectionManager sharedInstance];
  self.xmppStream = connectionManager.xmppStream;

  [MVBuddiesManager sharedInstance].xmppStream = connectionManager.xmppStream;
  
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *cloudAppEmail = [defaults stringForKey:kMVPreferencesCloudAppEmailKey];
  
  if(cloudAppEmail)
  {
    EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainCloudAppServiceName
                                                                          withUsername:cloudAppEmail];
    if(item)
    {
      NSString *cloudAppPassword = item.password;
      MVUploadAuthorization *uploadAuth = [[MVUploadAuthorization alloc]
                                           initWithCloudAppEmail:cloudAppEmail
                                           password:cloudAppPassword];
      [[MVURLKit sharedInstance] setUploadAuthorization:uploadAuth];
    }
  }
  
  NSView *contentView = self.window.contentView;
  
  MVNSContentView *tUINSView = [[MVNSContentView alloc] initWithFrame:contentView.bounds];
  tUINSView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [contentView addSubview:tUINSView];
  
  self.chatViewController = [[MVChatViewController alloc] initWithStream:self.xmppStream];
  self.chatViewController.view.frame = tUINSView.bounds;
  self.chatViewController.view.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                                  TUIViewAutoresizingFlexibleHeight;
  tUINSView.rootView = self.chatViewController.view;
  [self.chatViewController makeFirstResponder];
  [self.chatViewController addObserver:self forKeyPath:@"unreadMessagesCount"
                               options:0 context:NULL];
  
  if (connectionManager.hasEmptyConnectionInformation)
    [self openPreferences:self];
  else
    [connectionManager signIn];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
  if(self.xmppStream.isAuthenticated && !self.window.isMainWindow &&
     !self.accountController.window.isMainWindow)
    [self.window makeKeyAndOrderFront:self];
  return YES;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
  if([keyPath isEqualToString:@"unreadMessagesCount"] && object == self.chatViewController)
  {
    NSUInteger unreadMessagesCount = self.chatViewController.unreadMessagesCount;
    NSDockTile *dockTile = [NSApp dockTile];
    if(unreadMessagesCount > 0)
      dockTile.badgeLabel = [NSString stringWithFormat:@"%li",(unsigned long)unreadMessagesCount];
    else
      dockTile.badgeLabel = @"";
  }
}

#pragma mark Properties

- (MVAccountController*)accountController
{
  if(!accountController_)
  {
    accountController_ = [[MVAccountController alloc] initWithWindowNibName:@"Account"];
    accountController_.xmppStream = self.xmppStream;
  }
  return accountController_;
}

- (MVCloudAppAccountController*)cloudAppAccountController
{
  if(!cloudAppAccountController_)
  {
    cloudAppAccountController_ = [[MVCloudAppAccountController alloc]
                                  initWithWindowNibName:@"CloudAppAccount"];
  }
  return cloudAppAccountController_;
}

#pragma mark Menu Actions

- (IBAction)newTab:(id)sender
{
  [self.chatViewController newTab];
}

- (IBAction)previousTab:(id)sender
{
  [self.chatViewController previousTab];
}

- (IBAction)nextTab:(id)sender
{
  [self.chatViewController nextTab];
}

- (IBAction)closeTab:(id)sender
{
  if(self.window.isKeyWindow)
    [self.chatViewController closeTab];
  else
    [[NSApplication sharedApplication] sendAction:@selector(performClose:) to:nil from:nil];
}

- (IBAction)openPreferences:(id)sender
{
  [self.accountController showWindow:self];
  [self.cloudAppAccountController showWindow:self];
}

@end
