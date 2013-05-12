#import "MVController.h"

@interface MVChatViewController : NSObject <MVController>

@property (readonly) NSUInteger unreadMessagesCount;

- (id)initWithStream:(XMPPStream*)xmppStream;
- (void)newTab;
- (void)previousTab;
- (void)nextTab;
- (void)closeTab;

@end
