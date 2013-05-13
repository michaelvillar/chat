#import "MVCloudAppAccountController.h"
#import "EMKeychainItem.h"
#import "CLAPIEngine.h"
#import "MVURLKit.h"

@interface MVCloudAppAccountController () <CLAPIEngineDelegate>

@property (strong, readwrite) NSString *email;
@property (strong, readwrite) NSString *password;
@property (readwrite, getter = isLoading) BOOL loading;

- (IBAction)signInAction:(id)sender;

@end

@implementation MVCloudAppAccountController

@synthesize email = email_,
            password = password_,
            loading = loading_;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
  self = [super initWithWindowNibName:windowNibName];
  if(self)
  {

  }
  return self;
}

- (void)showWindow:(id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  self.email = [defaults stringForKey:kMVPreferencesCloudAppEmailKey];
  
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainCloudAppServiceName
                                                                        withUsername:self.email];
  if(item)
    self.password = item.password;
  
  [super showWindow:sender];
}

- (IBAction)signInAction:(id)sender
{
  self.loading = YES;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:self.email forKey:kMVPreferencesCloudAppEmailKey];
  [defaults synchronize];
  
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainCloudAppServiceName
                                                                        withUsername:self.email];
  if (item)
    item.password = self.password;
  else
    [EMGenericKeychainItem addGenericKeychainItemForService:kMVKeychainCloudAppServiceName
                                               withUsername:self.email
                                                   password:self.password];
  
  CLAPIEngine *engine = [CLAPIEngine engineWithDelegate:self];
  engine.clearsCookies = YES;
  engine.email = self.email;
  engine.password = self.password;
  if([engine isReady])
    [engine getAccountInformationWithUserInfo:nil];
  else
    self.loading = NO;
}

#pragma mark CLAPIEngineDelegate Methods

- (void)requestDidFailWithError:(NSError *)error
           connectionIdentifier:(NSString *)connectionIdentifier
                       userInfo:(id)userInfo
{
  if(self.loading)
    [[NSAlert alertWithMessageText:@"Couldn't sign in"
                     defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat:@"Please check your connection information"] runModal];
  self.loading = NO;
}

- (void)requestDidSucceedWithConnectionIdentifier:(NSString *)connectionIdentifier
                                         userInfo:(id)userInfo
{
  
  if(self.loading)
    [self close];
  self.loading = NO;
  
  MVUploadAuthorization *uploadAuth = [[MVUploadAuthorization alloc]
                                       initWithCloudAppEmail:self.email
                                       password:self.password];
  [[MVURLKit sharedInstance] setUploadAuthorization:uploadAuth];
}

@end
