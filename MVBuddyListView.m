#import "MVBuddyListView.h"
#import "MVRoundedTextView.h"
#import "MVBuddyListTableView.h"
#import "NSEvent+CharacterDetection.h"
#import "TUIView+Easing.h"

@interface MVBuddyListView () <MVRoundedTextViewDelegate>

@property (strong, readwrite) TUITableView *tableView;
@property (strong, readwrite) TUIView *searchFieldContainerView;
@property (strong, readwrite) TUIView *searchFieldView;
@property (strong, readwrite) MVRoundedTextView *searchField;
@property (readwrite, getter = isSearchFieldVisible) BOOL searchFieldVisible;
@property (strong, readwrite) TUIView *maskView;

@end

@implementation MVBuddyListView

@synthesize tableView = tableView_,
            searchFieldContainerView = searchFieldContainerView_,
            searchFieldView = searchFieldView_,
            searchField = searchField_,
            searchFieldVisible = searchFieldVisible_,
            maskView = maskView_,
            delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.backgroundColor = [TUIColor whiteColor];
    
    tableView_ = [[MVBuddyListTableView alloc] initWithFrame:self.bounds
                                                       style:TUITableViewStylePlain];
    tableView_.backgroundColor = [TUIColor whiteColor];
    tableView_.opaque = NO;
    tableView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth |
                                  TUIViewAutoresizingFlexibleHeight;
    tableView_.animateSelectionChanges = NO;
    tableView_.alwaysBounceVertical = YES;
    
    [self addSubview:tableView_];
    
    searchFieldContainerView_ = [[TUIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                          self.bounds.size.width,
                                                                          37)];
    searchFieldContainerView_.userInteractionEnabled = NO;
    searchFieldContainerView_.backgroundColor = [TUIColor clearColor];
    searchFieldContainerView_.opaque = NO;
    
    CGRect searchFieldViewFrame = CGRectMake(0, searchFieldContainerView_.bounds.size.height,
                                             searchFieldContainerView_.bounds.size.width,
                                             searchFieldContainerView_.bounds.size.height);
    searchFieldView_ = [[TUIView alloc] initWithFrame:searchFieldViewFrame];
    searchFieldView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    searchFieldView_.opaque = NO;
    searchFieldView_.backgroundColor = [TUIColor clearColor];
    searchFieldView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      NSColor *startColor = [NSColor colorWithDeviceWhite:1 alpha:0.8];
      NSColor *endColor = [NSColor colorWithDeviceWhite:1 alpha:0];
      NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                              startColor, 0.0,
                              startColor, 0.7,
                              endColor, 1.0,
                              nil];
      [gradient drawFromPoint:CGPointMake(0, view.bounds.size.height)
                      toPoint:CGPointMake(0, 0) options:0];
    };
    
    CGRect searchFieldFrame = CGRectMake(4, 4, searchFieldView_.bounds.size.width - 8, 29);
    searchField_ = [[MVRoundedTextView alloc] initWithFrame:searchFieldFrame];
    searchField_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    searchField_.placeholder = @"Search buddy";
    searchField_.multiline = NO;
    searchField_.delegate = self;
    
    [searchFieldContainerView_ addSubview:searchFieldView_];
    [searchFieldView_ addSubview:searchField_];
    [self addSubview:self.searchFieldContainerView];

    searchFieldVisible_ = NO;
    delegate_ = nil;
    
    maskView_ = [[TUIView alloc] initWithFrame:self.bounds];
    maskView_.opaque = NO;
    maskView_.backgroundColor = [TUIColor clearColor];
    maskView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      // clipping mask
      float radius = 3.5;
      rect = view.bounds;
      NSBezierPath *path = [NSBezierPath bezierPath];
      [path moveToPoint:CGPointMake(rect.size.width, rect.size.height / 2)];
      [path appendBezierPathWithArcFromPoint:CGPointMake(rect.size.width, 0)
                                     toPoint:CGPointMake(rect.size.width / 2, 0)
                                      radius:radius];
      [path appendBezierPathWithArcFromPoint:CGPointMake(0, 0)
                                     toPoint:CGPointMake(0, rect.size.height / 2)
                                      radius:radius];
      [path lineToPoint:CGPointMake(0, rect.size.height)];
      [path lineToPoint:CGPointMake(rect.size.width, rect.size.height)];
      [path closePath];
      
      [[NSColor blackColor] set];
      [path fill];
    };
    [maskView_ setNeedsDisplay];
    
    // to make it work with retina graphics
    maskView_.userInteractionEnabled = NO;
    [self addSubview:maskView_];
    
    // apply mask
    self.layer.mask = maskView_.layer;
  }
  return self;
}

- (BOOL)makeFirstResponder
{
  if(self.isSearchFieldVisible)
    return [self.searchField makeFirstResponder];
  return [super makeFirstResponder];
}

- (void)setSearchFieldVisible:(BOOL)visible animated:(BOOL)animated
{
  if(self.searchFieldVisible == visible)
    return;
  
  self.searchFieldVisible = visible;
  __block CGRect rect = self.searchFieldView.frame;
  __block CGRect tableViewRect = self.tableView.frame;
  self.searchFieldContainerView.userInteractionEnabled = self.searchFieldVisible;
  if(self.searchFieldVisible) {
    [TUIView animateWithDuration:0.45 animations:^{
      [TUIView setEasing:[CAMediaTimingFunction functionWithControlPoints:0.20 :1.4 :0.46 :1]];
      rect.origin.y = 0;
      self.searchFieldView.frame = rect;
      
      tableViewRect.origin.y = - rect.size.height;
      self.tableView.frame = tableViewRect;
    } completion:^(BOOL finished) {
      if(!self.searchFieldVisible)
        return;
      tableViewRect.origin.y = 0;
      tableViewRect.size.height = self.frame.size.height - rect.size.height;
      self.tableView.frame = tableViewRect;
      [self.tableView scrollToTopAnimated:NO];
    }];
    [self.searchField setEditable:YES];
    [self.searchField makeFirstResponder];
  }
  else {
    tableViewRect.origin.y = - (rect.size.height - 2);
    tableViewRect.size.height = self.frame.size.height;
    self.tableView.frame = tableViewRect;
    [self.tableView scrollToTopAnimated:NO];
    [CATransaction flush];

    [TUIView animateWithDuration:0.2 animations:^{
      [TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
      rect.origin.y = rect.size.height;
      self.searchFieldView.frame = rect;
      
      tableViewRect.origin.y = 0;
      self.tableView.frame = tableViewRect;
    } completion:^(BOOL finished) {
      if(self.searchFieldVisible)
        return;
      [self.searchField setEditable:NO];
      self.searchField.text = @"";
    }];
  }
  
  if([self.delegate respondsToSelector:@selector(buddyListViewDidChangeSearchFieldVisibility:)])
    [self.delegate buddyListViewDidChangeSearchFieldVisibility:self];
}

- (NSString*)searchFieldText
{
  return self.searchField.text.copy;
}

- (void)layoutSubviews
{
  self.maskView.frame = self.bounds;
  self.searchFieldContainerView.frame = CGRectMake(0, self.bounds.size.height -
                                                   self.searchFieldContainerView.frame.size.height,
                                                   self.bounds.size.width,
                                                   self.searchFieldContainerView.frame.size.height);
}

- (void)performFindPanelAction:(id)sender
{
  [self setSearchFieldVisible:YES animated:YES];
}

#pragma mark Events Handling

- (void)mouseDown:(NSEvent *)theEvent
{
  [self makeFirstResponder];
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)keyDown:(NSEvent *)event
{
  if(event.isDigit || event.isChar || self.isSearchFieldVisible)
  {
    [self.searchField setSelectedRange:NSMakeRange(0, self.searchField.text.length)];
    [self.searchField makeFirstResponder];
    CGPoint location = CGPointMake(10, 5);
    location = [self.searchField convertPoint:location toView:nil];
    location = [self.nsView convertPoint:location toView:nil];
    NSEvent *keyEvent = [NSEvent keyEventWithType:event.type
                                         location:location
                                    modifierFlags:event.modifierFlags
                                        timestamp:event.timestamp
                                     windowNumber:event.windowNumber
                                          context:[NSGraphicsContext currentContext]
                                       characters:event.characters
                      charactersIgnoringModifiers:event.charactersIgnoringModifiers
                                        isARepeat:event.isARepeat
                                          keyCode:event.keyCode];
    [self.nsWindow postEvent:keyEvent atStart:YES];
    [self setSearchFieldVisible:YES animated:YES];
  }
  else if(event.keyCode == 125)
    [self selectNext];
  else if(event.keyCode == 126)
    [self selectPrevious];
  else if(event.keyCode == 36)
  {
    if ([self.tableView.delegate respondsToSelector:@selector(tableView:didClickRowAtIndexPath:withEvent:)]) {
      TUIFastIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
      [self.tableView.delegate tableView:self.tableView didClickRowAtIndexPath:indexPath withEvent:nil];
    }
  }
}

#pragma mark Private Methods

- (void)selectNext
{
  TUIFastIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
  if(!indexPath)
    indexPath = [TUIFastIndexPath indexPathForRow:0 inSection:0];
  else if(indexPath.row + 1 >= [self.tableView numberOfRowsInSection:0])
    return;
  else
    indexPath = [TUIFastIndexPath indexPathForRow:indexPath.row + 1 inSection:0];
  [self.tableView selectRowAtIndexPath:indexPath animated:NO
                        scrollPosition:TUITableViewScrollPositionToVisible];
}

- (void)selectPrevious
{
  TUIFastIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
  if(!indexPath)
    indexPath = [TUIFastIndexPath indexPathForRow:0 inSection:0];
  else if(indexPath.row == 0)
    return;
  else
    indexPath = [TUIFastIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
  [self.tableView selectRowAtIndexPath:indexPath animated:NO
                        scrollPosition:TUITableViewScrollPositionToVisible];
}

#pragma mark MVRoundedTextViewDelegate Methods

- (void)roundedTextViewTextDidChange:(MVRoundedTextView *)textView
{
  if([self.delegate respondsToSelector:@selector(buddyListViewDidChangeSearchFieldValue:)])
    [self.delegate buddyListViewDidChangeSearchFieldValue:self];
}

- (void)roundedTextViewCancelOperation:(MVRoundedTextView*)roundedTextView
{
  [self setSearchFieldVisible:NO animated:YES];
  roundedTextView.text = @"";
  [self makeFirstResponder];
}

- (BOOL)roundedTextView:(MVRoundedTextView *)roundedTextView sendString:(NSString *)string
{
  if(self.tableView.indexPathForSelectedRow)
  {
    if([self.tableView.delegate respondsToSelector:@selector(tableView:
                                                             didClickRowAtIndexPath:withEvent:)])
      [self.tableView.delegate tableView:self.tableView
                  didClickRowAtIndexPath:self.tableView.indexPathForSelectedRow
                               withEvent:nil];
    return YES;
  }
  return NO;
}

- (BOOL)roundedTextView:(MVRoundedTextView *)roundedTextView doCommandBySelector:(SEL)selector
{
  if(!self.isSearchFieldVisible || [self.tableView numberOfRowsInSection:0] == 0)
    return NO;
  if(selector == @selector(moveDown:))
  {
    [self selectNext];
    return YES;
  }
  else if(selector == @selector(moveUp:))
  {
    [self selectPrevious];
    return YES;
  }
  return NO;
}

@end
