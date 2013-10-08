#import "MVPreferencesController.h"
#import "MVXMPPAccount.h"
#import "MVURLKit.h"
#import "MVXMPP.h"
#import "EMKeychainItem.h"
#import "CLAPIEngine.h"

@interface MVPreferencesController () <CLAPIEngineDelegate, MVXMPPDelegate>

@property (strong, readwrite) NSMutableArray *gmailAccounts;
@property (strong, readwrite) NSString *gmailEmail;
@property (strong, readwrite) NSString *gmailPassword;
@property (strong, readwrite) NSString *cloudappEmail;
@property (strong, readwrite) NSString *cloudappPassword;
@property (readwrite, getter = isLoading) BOOL loading;
@property (strong, readwrite) IBOutlet NSMenu *gmailMenu;
@property (strong, readwrite) NSArray *cachedItemArray;
@property (strong, readwrite) IBOutlet NSTextField *gmailEmailTextField;
@property (strong, readwrite) IBOutlet NSPopUpButton *gmailPopUpButton;
@property (strong, readwrite) IBOutlet NSButton *deleteButton;

- (IBAction)saveGmailAccount:(id)sender;
- (IBAction)deleteGmailAccount:(id)sender;
- (IBAction)saveCloudappAccount:(id)sender;
- (IBAction)addGmailAccount:(id)sender;
- (void)refreshMenu;

@end

@implementation MVPreferencesController

@synthesize gmailAccounts = gmailAccounts_,
            gmailEmail = gmailEmail_,
            gmailPassword = gmailPassword_,
            cloudappEmail = cloudappEmail_,
            cloudappPassword = cloudappPassword_,
            loading = loading_,
            gmailMenu = gmailMenu_,
            cachedItemArray = cachedItemArray_,
            gmailEmailTextField = gmailEmailTextField_,
            gmailPopUpButton = gmailPopUpButton_,
            deleteButton = deleteButton_;

- (void)showWindow:(id)sender
{
  self.loading = NO;
  self.gmailAccounts = [NSMutableArray array];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSArray *gmailEmails = [defaults arrayForKey:kMVPreferencesGmailEmailsKey];
  if (gmailEmails) {
    for (NSString *email in gmailEmails) {
      MVXMPPAccount *account = [[MVXMPPAccount alloc] initWithEmail:email];
      [self.gmailAccounts addObject:account];
    }
  }
  
  self.cloudappEmail = [defaults stringForKey:kMVPreferencesCloudAppEmailKey];
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainCloudAppServiceName
                                                                        withUsername:self.cloudappEmail];
  if(item)
    self.cloudappPassword = item.password;
  
  [self refreshMenu];
  
  [super showWindow:sender];
}

- (void)awakeFromNib
{
  [[MVXMPP xmpp] addDelegate:self];
  self.cachedItemArray = [NSArray arrayWithArray:self.gmailMenu.itemArray];
  [self refreshMenu];
}

- (IBAction)saveGmailAccount:(id)sender
{
  MVXMPPAccount *account = [self currentAccount];
  if (!account) {
    account = [[MVXMPPAccount alloc] init];
    [self.gmailAccounts addObject:account];
  }
  account.email = self.gmailEmail.copy;
  account.password = self.gmailPassword.copy;
  [account savePassword];
  [self refreshMenu];
  [self.gmailMenu performActionForItemAtIndex:[self.gmailAccounts indexOfObject:account]];
  [self saveEmails];
  [[MVXMPP xmpp] refreshFromPreferences];
}

- (IBAction)deleteGmailAccount:(id)sender
{
  MVXMPPAccount *account = [self currentAccount];
  if (account) {
    [self.gmailAccounts removeObject:account];
    [self refreshMenu];
    [self saveEmails];
  }
}

- (IBAction)saveCloudappAccount:(id)sender
{
  self.loading = YES;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:self.cloudappEmail forKey:kMVPreferencesCloudAppEmailKey];
  [defaults synchronize];
  
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainCloudAppServiceName
                                                                        withUsername:self.cloudappEmail];
  if (item)
    item.password = self.cloudappPassword;
  else
    [EMGenericKeychainItem addGenericKeychainItemForService:kMVKeychainCloudAppServiceName
                                               withUsername:self.cloudappEmail
                                                   password:self.cloudappPassword];
  
  CLAPIEngine *engine = [CLAPIEngine engineWithDelegate:self];
  engine.clearsCookies = YES;
  engine.email = self.cloudappEmail;
  engine.password = self.cloudappPassword;
  if([engine isReady])
    [engine getAccountInformationWithUserInfo:nil];
  else
    self.loading = NO;
}

- (IBAction)addGmailAccount:(NSMenuItem*)sender
{
  [self updateFromSelected];
}

- (void)refreshMenu
{
  if(!self.gmailMenu)
    return;
  
  [self.gmailMenu removeAllItems];
  
  for (MVXMPPAccount *account in self.gmailAccounts) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:account.email
                                                  action:@selector(switchGmailAccount:)
                                           keyEquivalent:@""];
    item.target = self;
    item.representedObject = account;
    [item setEnabled:YES];
    if([[MVXMPP xmpp] isEmailConnected:account.email])
      item.image = [NSImage imageNamed:@"icon_online"];
    [self.gmailMenu addItem:item];
  }
  
  for (NSMenuItem *item in self.cachedItemArray) {
    item.state = NSOffState;
    [self.gmailMenu addItem:item];
  }
  
  [self updateFromSelected];
}

- (void)switchGmailAccount:(NSMenuItem*)sender
{
  [self updateFromSelected];
}

- (MVXMPPAccount*)currentAccount
{
  NSMenuItem *item = self.gmailPopUpButton.selectedItem;
  if (!item)
    item = [self.gmailMenu itemAtIndex:0];
  return (MVXMPPAccount*)(item.representedObject);
}

- (void)updateFromSelected
{
  MVXMPPAccount *account = [self currentAccount];
  [self.deleteButton setEnabled:account != nil];
  if (account) {
    self.gmailEmail = account.email.copy;
    self.gmailPassword = account.password.copy;
  }
  else {
    self.gmailEmail = @"";
    self.gmailPassword = @"";
  }
  [self.window makeFirstResponder:self.gmailEmailTextField];
}

- (void)saveEmails
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *gmailEmails = [NSMutableArray array];
  for (MVXMPPAccount *account in self.gmailAccounts) {
    [gmailEmails addObject:account.email];
  }
  [defaults setObject:gmailEmails forKey:kMVPreferencesGmailEmailsKey];
  [defaults synchronize];
}

#pragma mark CLAPIEngineDelegate Methods

- (void)requestDidFailWithError:(NSError *)error
           connectionIdentifier:(NSString *)connectionIdentifier
                       userInfo:(id)userInfo
{
  if(self.loading)
    [[NSAlert alertWithMessageText:@"Couldn't sign in"
                     defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat:@"Please check your CloudApp connection information"] runModal];
  self.loading = NO;
}

- (void)requestDidSucceedWithConnectionIdentifier:(NSString *)connectionIdentifier
                                         userInfo:(id)userInfo
{
  
  self.loading = NO;
  
  MVUploadAuthorization *uploadAuth = [[MVUploadAuthorization alloc] initWithCloudAppEmail:self.cloudappEmail
                                                                                  password:self.cloudappPassword];
  [[MVURLKit sharedInstance] setUploadAuthorization:uploadAuth];
}

#pragma MVXMPPDelegate Methods

- (void)xmppDidConnect:(XMPPJID *)jid
{
  [self refreshMenu];
}

- (void)xmppDidFailToConnect:(XMPPJID *)jid
{
  [self refreshMenu];
}

- (void)xmppDidDisconnect:(XMPPJID *)jid
{
  [self refreshMenu];
}

@end
