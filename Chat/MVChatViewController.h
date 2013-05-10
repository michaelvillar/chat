#import "MVController.h"

@interface MVChatViewController : NSObject <MVController>

- (id)initWithStream:(XMPPStream*)xmppStream;
- (void)newTab;

@end
