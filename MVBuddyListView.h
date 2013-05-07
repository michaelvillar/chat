//
//  MVBuddyListView.h
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import <TwUI/TUIKit.h>

@interface MVBuddyListView : TUIView

@property (strong, readonly) TUITableView *tableView;

- (void)setSearchFieldVisible:(BOOL)visible animated:(BOOL)animated;

@end
