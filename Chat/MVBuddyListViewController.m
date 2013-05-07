//
//  MVBuddyListViewController.m
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import "MVBuddyListViewController.h"
#import "MVBuddyViewCell.h"

static NSGradient *backgroundGradient = nil;

@interface MVBuddyListViewController () <TUITableViewDataSource, TUITableViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPRoster *xmppRoster;
@property (strong, readwrite) XMPPvCardAvatarModule *xmppAvatarModule;
@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) TUITableView *tableView;
@property (strong, readwrite) NSArray *users;

@end

@implementation MVBuddyListViewController

@synthesize xmppStream = xmppStream_,
            xmppRoster = xmppRoster_,
            xmppAvatarModule = xmppAvatarModule_,
            tableView = tableView_,
            users = users_,
            delegate = delegate_;

+ (void)initialize
{
  if(!backgroundGradient)
  {
    NSColor *bottomColor = [NSColor colorWithDeviceRed:0.8863
                                                 green:0.9059
                                                  blue:0.9529
                                                 alpha:1.0000];
    NSColor *topColor = [NSColor colorWithDeviceRed:0.9216
                                              green:0.9373
                                               blue:0.9686
                                              alpha:1.0000];
    
    backgroundGradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                       endingColor:topColor];
  }
}

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
    
    self.view = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    self.view.drawRect = ^(TUIView *view, CGRect rect) {
      [backgroundGradient drawInRect:view.bounds
                               angle:90];
      
      [[NSColor colorWithDeviceRed:0.9608 green:0.9686 blue:0.9843 alpha:1.0000] set];
      NSRectFill(CGRectMake(0, view.bounds.size.height - 1, view.bounds.size.width, 1));
    };

    tableView_ = [[TUITableView alloc] initWithFrame:self.view.bounds
                                               style:TUITableViewStylePlain];
    tableView_.backgroundColor = [TUIColor clearColor];
    tableView_.opaque = NO;
    tableView_.delegate = self;
    tableView_.dataSource = self;
    tableView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                  TUIViewAutoresizingFlexibleHeight;
    tableView_.animateSelectionChanges = NO;
    
    [self.view addSubview:tableView_];
    
    users_ = [NSArray array];
    
    [self reload];
    
    [xmppRoster_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  return self;
}

- (void)reload
{
  XMPPRosterMemoryStorage *storage = self.xmppRoster.xmppRosterStorage;
  self.users = [storage sortedUsersByName];
  [self.tableView reloadData];
}

#pragma mark TUITableViewDelegate Methods

- (void)tableView:(TUITableView *)tableView
didClickRowAtIndexPath:(TUIFastIndexPath *)indexPath
        withEvent:(NSEvent *)event
{
  NSObject<XMPPUser> *user = [self.users objectAtIndex:indexPath.row];
  if([self.delegate respondsToSelector:@selector(buddyListViewController:didClickBuddy:)])
    [self.delegate buddyListViewController:self didClickBuddy:user];
}

#pragma mark TUITableViewDataSource Methods

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
  return self.users.count;
}

- (CGFloat)tableView:(TUITableView *)tableView
heightForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
  return 36;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView
          cellForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
  NSObject<XMPPUser> *user = [self.users objectAtIndex:indexPath.row];
  
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
  [cell setNeedsDisplay];
	return cell;
}

#pragma mark XMPPRosterMemoryStorageDelegate Methods

- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
  NSLog(@"did change!");
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
  NSLog(@"did receipve photo for %@",jid);
}

@end
