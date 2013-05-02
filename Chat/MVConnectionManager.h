#import <Foundation/Foundation.h>

#define kMVConnectionSuccessNotification @"kMVConnectionSuccessNotification"
#define kMVConnectionErrorNotification @"kMVConnectionErrorNotification"

@interface MVConnectionManager : NSObject

@property (strong, readonly) XMPPStream *xmppStream;
@property (readonly, getter = hasEmptyConnectionInformation) BOOL emptyConnectionInformation;

+ (MVConnectionManager*)sharedInstance;
- (void)signIn;

@end
