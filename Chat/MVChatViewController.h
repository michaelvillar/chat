#import <Foundation/Foundation.h>

@interface MVChatViewController : NSObject

@property (strong, readonly) TUIView *view;

- (id)initWithStream:(XMPPStream*)xmppStream;
- (void)newTab;

@end
