#import "MVXMPPAccount.h"
#import "EMKeychainItem.h"

@implementation MVXMPPAccount

@synthesize email = email_,
            password = password_;

- (id)initWithEmail:(NSString*)email
{
  self = [super init];
  if (self)
  {
    email_ = email;
    EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainServiceName
                                                                          withUsername:self.email];
    if (item)
      self.password = item.password;
  }
  return self;
}

- (void)savePassword
{
  EMGenericKeychainItem *item = [EMGenericKeychainItem genericKeychainItemForService:kMVKeychainServiceName
                                                                        withUsername:self.email];
  if (item)
    item.password = self.password;
  else
    [EMGenericKeychainItem addGenericKeychainItemForService:kMVKeychainServiceName
                                               withUsername:self.email
                                                   password:self.password];
}

@end
