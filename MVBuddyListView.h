#import <TwUI/TUIKit.h>

@protocol MVBuddyListViewDelegate;

@interface MVBuddyListView : TUIView

@property (strong, readonly) TUITableView *tableView;
@property (readonly, getter = isSearchFieldVisible) BOOL searchFieldVisible;
@property (readonly, nonatomic) NSString *searchFieldText;
@property (readwrite, weak) NSObject <MVBuddyListViewDelegate> *delegate;

- (void)setSearchFieldVisible:(BOOL)visible animated:(BOOL)animated;

@end

@protocol MVBuddyListViewDelegate
@optional
- (void)buddyListViewDidChangeSearchFieldValue:(MVBuddyListView*)buddyListView;
- (void)buddyListViewDidChangeSearchFieldVisibility:(MVBuddyListView*)buddyListView;
@end