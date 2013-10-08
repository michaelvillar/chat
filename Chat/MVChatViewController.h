#import "MVController.h"

@interface MVChatViewController : NSObject <MVController>

@property (readonly) NSUInteger unreadMessagesCount;

- (void)newTab;
- (void)previousTab;
- (void)nextTab;
- (void)closeTab;

@end
