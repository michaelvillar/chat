@interface MVXMPPAccount : NSObject

@property (strong, readwrite) NSString *email;
@property (strong, readwrite) NSString *password;

- (id)initWithEmail:(NSString*)email;
- (void)savePassword;

@end
