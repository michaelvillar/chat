#import "MVAccountController.h"
#import "EMKeychainItem.h"
#import "MVConnectionManager.h"

@interface MVAccountController ()

@property (strong, readwrite) NSString *email;
@property (strong, readwrite) NSString *password;
@property (readwrite, getter = isLoading) BOOL loading;

- (IBAction)signInAction:(id)sender;

@end

@implementation MVAccountController

@synthesize xmppStream = xmppStream_,
            email = email_,
            password = password_,
            loading = loading_;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
  self = [super initWithWindowNibName:windowNibName];
  if(self)
  {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(connectionSuccess:)
               name:kMVConnectionSuccessNotification object:nil];
    [nc addObserver:self selector:@selector(connectionError:)
               name:kMVConnectionErrorNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showWindow:(id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  self.email = [defaults stringForKey:kMVPreferencesGmailEmailKey];
  
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainServiceName
                                                                        withUsername:self.email];
  if(item)
    self.password = item.password;
  
  [super showWindow:sender];
}

- (IBAction)signInAction:(id)sender
{
  self.loading = YES;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:self.email forKey:kMVPreferencesGmailEmailKey];
  [defaults synchronize];
  
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainServiceName
                                                                        withUsername:self.email];
  if (item)
    item.password = self.password;
  else
    [EMGenericKeychainItem addGenericKeychainItemForService:kMVKeychainServiceName
                                               withUsername:self.email
                                                   password:self.password];

  [[MVConnectionManager sharedInstance] signIn];
}

#pragma mark Notifications

- (void)connectionSuccess:(NSNotification*)notification
{
  if(self.loading)
    [self close];
  self.loading = NO;
}

- (void)connectionError:(NSNotification*)notification
{
  if(self.loading)
    [[NSAlert alertWithMessageText:@"Couldn't sign in"
                     defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat:@"Please check your connection information"] runModal];
  self.loading = NO;
}

@end
