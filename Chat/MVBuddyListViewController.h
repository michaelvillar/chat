//
//  MVBuddyListViewController.h
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import <TwUI/TUIKit.h>

@protocol MVBuddyListViewControllerDelegate;

@interface MVBuddyListViewController : NSObject

@property (strong, readonly) TUIView *view;
@property (weak, readwrite) NSObject <MVBuddyListViewControllerDelegate> *delegate;

- (id)initWithStream:(XMPPStream*)xmppStream;
- (void)reload;

@end

@protocol MVBuddyListViewControllerDelegate

@optional
- (void)buddyListViewController:(MVBuddyListViewController*)controller
                  didClickBuddy:(NSObject<XMPPUser>*)user;

@end