#import "MVAppDelegate.h"
#import "MVChatViewController.h"
#import "MVvCardFileDiskModuleStorage.h"
#import "MVPreferencesController.h"
#import "MVNSContentView.h"
#import "MVUploadAuthorization.h"
#import "MVURLKit.h"
#import "MVBuddiesManager.h"
#import "MVHistoryManager.h"
#import "EMKeychainItem.h"
#import "MVXMPP.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

@interface MVAppDelegate ()

@property (strong, readwrite) MVXMPP *xmpp;
@property (strong, readwrite) MVChatViewController *chatViewController;
@property (strong, readwrite, nonatomic) MVPreferencesController *preferencesController;

@end

@implementation MVAppDelegate

@synthesize xmpp = xmpp_,
            chatViewController = chatViewController_,
            preferencesController = preferencesController_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.xmpp = [MVXMPP xmpp];
  [self.xmpp refreshFromPreferences];
  
  
  [DDLog addLogger:[DDTTYLogger sharedInstance]];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], kMVPreferencesShowOfflineBuddiesKey,
                               nil]];
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
  
  self.chatViewController = [[MVChatViewController alloc] init];
  self.chatViewController.view.frame = tUINSView.bounds;
  self.chatViewController.view.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                                  TUIViewAutoresizingFlexibleHeight;
  tUINSView.rootView = self.chatViewController.view;
  [self.chatViewController makeFirstResponder];
  [self.chatViewController addObserver:self forKeyPath:@"unreadMessagesCount"
                               options:0 context:NULL];
  
  if (self.xmpp.hasEmptyConnectionInformation)
    [self openPreferences:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
  if(!self.xmpp.hasEmptyConnectionInformation && !self.window.isMainWindow &&
     !self.preferencesController.window.isMainWindow)
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

- (MVPreferencesController*)preferencesController
{
  if(!preferencesController_)
  {
    preferencesController_ = [[MVPreferencesController alloc] initWithWindowNibName:@"Preferences"];
  }
  return preferencesController_;
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
  [self.preferencesController showWindow:self];
}

@end
