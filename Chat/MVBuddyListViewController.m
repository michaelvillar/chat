#import "MVBuddyListViewController.h"
#import "MVBuddyViewCell.h"
#import "MVBuddyListView.h"

@interface MVBuddyListViewController () <TUITableViewDataSource,
                                         TUITableViewDelegate,
                                         MVBuddyListViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPRoster *xmppRoster;
@property (strong, readwrite) XMPPvCardAvatarModule *xmppAvatarModule;
@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) MVBuddyListView *buddyListView;
@property (strong, readwrite) TUITableView *tableView;
@property (strong, readwrite) NSArray *users;
@property (strong, readwrite) NSArray *filteredUsers;

@end

@implementation MVBuddyListViewController

@synthesize xmppStream = xmppStream_,
            xmppRoster = xmppRoster_,
            xmppAvatarModule = xmppAvatarModule_,
            view = view_,
            buddyListView = buddyListView_,
            tableView = tableView_,
            users = users_,
            filteredUsers = filteredUsers_,
            delegate = delegate_;

- (id)initWithStream:(XMPPStream*)xmppStream
{
  self = [super init];
  if(self)
  {
    delegate_ = nil;
    xmppStream_ = xmppStream;
    xmppRoster_ = (XMPPRoster*)[xmppStream moduleOfClass:[XMPPRoster class]];
    xmppAvatarModule_ = (XMPPvCardAvatarModule*)[xmppStream moduleOfClass:
                                                 [XMPPvCardAvatarModule class]];
    
    [xmppStream_ autoAddDelegate:self
                  delegateQueue:dispatch_get_main_queue()
               toModulesOfClass:[XMPPvCardAvatarModule class]];
    
    self.view = self.buddyListView = [[MVBuddyListView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    self.tableView = self.buddyListView.tableView;
    self.tableView.maintainContentOffsetAfterReload = YES;
    [self.tableView scrollToTopAnimated:NO];
    self.buddyListView.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    users_ = [NSArray array];
    filteredUsers_ = [NSArray array];
    
    [self reload];
    
    [xmppRoster_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  return self;
}

- (void)makeFirstResponder
{
  [self.view makeFirstResponder];
}

- (void)reload
{
  XMPPRosterMemoryStorage *storage = self.xmppRoster.xmppRosterStorage;
  NSArray *users = [storage unsortedUsers];
  self.users = [users sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSObject<XMPPUser> *user1 = (NSObject<XMPPUser>*)obj1;
    NSObject<XMPPUser> *user2 = (NSObject<XMPPUser>*)obj2;
    NSString *user1Name = (user1.nickname ? user1.nickname : user1.jid.bare);
    NSString *user2Name = (user2.nickname ? user2.nickname : user2.jid.bare);
    return [user1Name.lowercaseString compare:user2Name.lowercaseString];
  }];
  
  if(self.buddyListView.isSearchFieldVisible && self.buddyListView.searchFieldText.length > 0)
  {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"nickname CONTAINS[cd] %@ OR jid.bare CONTAINS[cd] %@",
                              self.buddyListView.searchFieldText,
                              self.buddyListView.searchFieldText];
    self.filteredUsers = [self.users filteredArrayUsingPredicate:predicate];
  }
  else
    self.filteredUsers = self.users;
  
  [self.tableView reloadData];
}

#pragma mark TUITableViewDelegate Methods

- (void)tableView:(TUITableView *)tableView
didClickRowAtIndexPath:(TUIFastIndexPath *)indexPath
        withEvent:(NSEvent *)event
{
  NSObject<XMPPUser> *user = [self.filteredUsers objectAtIndex:indexPath.row];
  [self.buddyListView setSearchFieldVisible:NO animated:YES];
  if([self.delegate respondsToSelector:@selector(buddyListViewController:didClickBuddy:)])
    [self.delegate buddyListViewController:self didClickBuddy:user];
}

#pragma mark TUITableViewDataSource Methods

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
  return self.filteredUsers.count;
}

- (CGFloat)tableView:(TUITableView *)tableView
heightForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
  return 36;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView
          cellForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
  NSObject<XMPPUser> *user = [self.filteredUsers objectAtIndex:indexPath.row];
  
  MVBuddyViewCell *cell = reusableTableCellOfClass(tableView, MVBuddyViewCell);
  cell.email = user.jid.bare;
  cell.fullname = user.nickname;
  cell.online = user.isOnline;
  cell.alternate = indexPath.row % 2 == 1;
  cell.firstRow = indexPath.row == 0;
  cell.lastRow = (indexPath.row == [self tableView:tableView
                             numberOfRowsInSection:indexPath.section] - 1);
  cell.representedObject = user.jid;
  NSData *photoData = [self.xmppAvatarModule photoDataForJID:user.jid];
  if(photoData)
  {
    cell.avatar = [TUIImage imageWithData:photoData];
  }
  else
  {
    cell.avatar = nil;
  }
  [cell setNeedsDisplay];
	return cell;
}

#pragma mark XMPPRosterMemoryStorageDelegate Methods

- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
  [self reload];
}

#pragma mark XMPPvCardAvatarModuleDelegate Methods

- (void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule
              didReceivePhoto:(NSImage *)photo
                       forJID:(XMPPJID *)jid
{
  NSArray *visibleCells = self.tableView.visibleCells;
  for(MVBuddyViewCell *cell in visibleCells)
  {
    XMPPJID *cellJid = (XMPPJID*)cell.representedObject;
    if(cellJid && [cellJid isEqualToJID:jid options:XMPPJIDCompareBare])
    {
      cell.avatar = [TUIImage imageWithNSImage:photo];
      [cell setNeedsDisplay];
    }
  }
}

#pragma mark MVBuddyListViewDelegate Methods

- (void)buddyListViewDidChangeSearchFieldValue:(MVBuddyListView *)buddyListView
{
  [self reload];
}

- (void)buddyListViewDidChangeSearchFieldVisibility:(MVBuddyListView *)buddyListView
{
  [self reload];
}

@end
