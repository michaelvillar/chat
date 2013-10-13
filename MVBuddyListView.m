#import "MVBuddyListView.h"
#import "MVRoundedTextView.h"
#import "NSEvent+CharacterDetection.h"

static NSGradient *backgroundGradient = nil;

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

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    tableView_ = [[TUITableView alloc] initWithFrame:self.bounds
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
                                                                          39)];
    searchFieldContainerView_.userInteractionEnabled = NO;
    
    CGRect searchFieldViewFrame = CGRectMake(0, searchFieldContainerView_.bounds.size.height,
                                             searchFieldContainerView_.bounds.size.width,
                                             searchFieldContainerView_.bounds.size.height);
    searchFieldView_ = [[TUIView alloc] initWithFrame:searchFieldViewFrame];
    searchFieldView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    searchFieldView_.opaque = NO;
    searchFieldView_.backgroundColor = [TUIColor clearColor];
    searchFieldView_.drawRect = ^(TUIView *view, CGRect rect) {
      // bg
      NSColor *bottomColor = [NSColor colorWithDeviceRed:0.9059 green:0.9255 blue:0.9608 alpha:1];
      NSColor *topColor = [NSColor colorWithDeviceRed:0.9647 green:0.9725 blue:0.9843 alpha:1];
      NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                           endingColor:topColor];
      [gradient drawInRect:CGRectMake(0, 2, view.bounds.size.width, 36) angle:90];
      
      // shadow
      bottomColor = [NSColor colorWithDeviceRed:0.6784 green:0.7098 blue:0.7647 alpha:0];
      topColor = [NSColor colorWithDeviceRed:0.6784 green:0.7098 blue:0.7647 alpha:0.82];
      gradient = [[NSGradient alloc] initWithStartingColor:bottomColor
                                                           endingColor:topColor];
      [gradient drawInRect:CGRectMake(0, 0, view.bounds.size.width, 2) angle:90];
      
      // line
      [[NSColor colorWithDeviceRed:0.6118 green:0.6392 blue:0.6902 alpha:1.0000] set];
      [NSBezierPath fillRect:CGRectMake(0, 2, view.bounds.size.width, 0.5)];
    };
    [searchFieldView_ setNeedsDisplay];
    
    CGRect searchFieldFrame = CGRectMake(4, 6, searchFieldView_.bounds.size.width - 8, 29);
    searchField_ = [[MVRoundedTextView alloc] initWithFrame:searchFieldFrame];
    searchField_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    searchField_.placeholder = @"Search buddy";
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
    [TUIView animateWithDuration:0.2 animations:^{
      [TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
      rect.origin.y = 0;
      self.searchFieldView.frame = rect;
      
      tableViewRect.origin.y = - (rect.size.height - 2);
      self.tableView.frame = tableViewRect;
    } completion:^(BOOL finished) {
      tableViewRect.origin.y = 0;
      tableViewRect.size.height = self.frame.size.height - (rect.size.height - 2);
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

#pragma mark Drawing Methods

- (void)drawRect:(CGRect)rect
{
  [backgroundGradient drawInRect:self.bounds
                           angle:90];
  
  [[NSColor colorWithDeviceRed:0.9608 green:0.9686 blue:0.9843 alpha:1.0000] set];
  NSRectFill(CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1));
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
  if(!indexPath || indexPath.row + 1 >= [self.tableView numberOfRowsInSection:0])
    indexPath = [TUIFastIndexPath indexPathForRow:0 inSection:0];
  else
    indexPath = [TUIFastIndexPath indexPathForRow:indexPath.row + 1 inSection:0];
  [self.tableView selectRowAtIndexPath:indexPath animated:NO
                        scrollPosition:TUITableViewScrollPositionToVisible];
}

- (void)selectPrevious
{
  TUIFastIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
  if(!indexPath || indexPath.row == 0)
    indexPath = [TUIFastIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1
                                        inSection:0];
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
