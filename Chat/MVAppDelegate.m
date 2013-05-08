#import "MVAppDelegate.h"
#import "MVChatViewController.h"
#import "MVvCardFileDiskModuleStorage.h"
#import "MVAccountController.h"
#import "MVConnectionManager.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

@interface MVAppDelegate ()

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) MVChatViewController *chatViewController;
@property (strong, readwrite, nonatomic) MVAccountController *accountController;

@end

@implementation MVAppDelegate

@synthesize xmppStream = xmppStream_,
            chatViewController = chatViewController_,
            accountController = accountController_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  MVConnectionManager *connectionManager = [MVConnectionManager sharedInstance];
  self.xmppStream = connectionManager.xmppStream;
  
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
  NSView *contentView = self.window.contentView;
  
  TUINSView *tUINSView = [[TUINSView alloc] initWithFrame:contentView.bounds];
  tUINSView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [contentView addSubview:tUINSView];
  
  self.chatViewController = [[MVChatViewController alloc] initWithStream:self.xmppStream];
  self.chatViewController.view.frame = tUINSView.bounds;
  self.chatViewController.view.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                                  TUIViewAutoresizingFlexibleHeight;
  tUINSView.rootView = self.chatViewController.view;
  [self.chatViewController makeFirstResponder];
  
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

#pragma mark Menu Actions

- (IBAction)newTab:(id)sender
{
  [self.chatViewController newTab];
}

- (IBAction)openPreferences:(id)sender
{
  [self.accountController showWindow:self];
}

@end
