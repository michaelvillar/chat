#import "MVBuddyListTableView.h"

@implementation MVBuddyListTableView

- (CGRect)visibleRectForLayout
{
  CGRect rect = [super visibleRectForLayout];
  rect = CGRectInset(rect, 0, -20);
  rect = CGRectOffset(rect, 0, 20);
  return rect;
}

@end
