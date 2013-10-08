#import <TwUI/TUIKit.h>
#import "MVController.h"

@protocol MVBuddyListViewControllerDelegate;

@interface MVBuddyListViewController : NSObject <MVController>

@property (weak, readwrite) NSObject <MVBuddyListViewControllerDelegate> *delegate;

- (void)reload;
- (void)setSearchFieldVisible:(BOOL)visible;

@end

@protocol MVBuddyListViewControllerDelegate

@optional
- (void)buddyListViewController:(MVBuddyListViewController*)controller
                  didClickBuddy:(NSObject<XMPPUser>*)user;

@end