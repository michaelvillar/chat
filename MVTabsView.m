#import "MVTabsView.h"
#import "MVTabView.h"
#import "NSObject+PerformBlockAfterDelay.h"

#define kMVTabsViewAnimationDuration 0.3
#define kMVTabsViewOverflowMargin 30

@interface MVTabsView () <MVTabViewDelegate,
                           NSMenuDelegate>

@property (strong, readwrite) NSMutableArray *tabs;
@property (strong, readwrite) NSArray *tabsBeforeReordering;
@property (strong, readwrite) MVTabView *selectedTabView;
@property (readwrite) int totalWidth;
@property (readwrite) CGPoint pointWithinTabViewAtMouseDown;
@property (strong, readwrite) MVTabView *sortingTabView;
@property (strong, readwrite) TUIView *contentView;
@property (strong, readwrite) TUIView *maskView;
@property (strong, readwrite) TUIButton *overflowButton;
@property (strong, readwrite) TUIView *overflowButtonBreathingView;
@property (readwrite) BOOL menuOpened;

- (NSArray*)overflowTabs;
- (MVTabView*)tabForIdentifier:(NSObject*)identifier;
- (void)updateOverflowButtonVisibility;
- (void)updateOverflowButtonAppearance;
- (void)layoutTabs:(BOOL)animated;
- (void)updateTabszPositions;
- (void)reorderTabsFromSortingTabView;

@end

@implementation MVTabsView

@synthesize tabs              = tabs_,
            tabsBeforeReordering  = tabsBeforeReordering_,
            selectedTabView   = selectedTabView_,
            totalWidth        = totalWidth_,
            pointWithinTabViewAtMouseDown = pointWithinTabViewAtMouseDown_,
            sortingTabView    = sortingTabView_,
            contentView       = contentView_,
            maskView          = maskView_,
            overflowButton    = overflowButton_,
            overflowButtonBreathingView = overflowButtonBreathingView_,
            menuOpened        = menuOpened_,
            delegate          = delegate_;

#pragma mark -
#pragma mark Constructor

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    self.clipsToBounds = YES;

    __block MVTabsView *tabsView = self;

    tabs_ = [[NSMutableArray alloc] init];
    tabsBeforeReordering_ = nil;
    selectedTabView_ = nil;
    delegate_ = nil;
    totalWidth_ = 0;
    pointWithinTabViewAtMouseDown_ = CGPointZero;
    sortingTabView_ = nil;
    menuOpened_ = NO;

    contentView_ = [[TUIView alloc] initWithFrame:self.bounds];
    contentView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    [self addSubview:contentView_];

    CGRect overflowFrame = CGRectMake(self.bounds.size.width - 16 - 8,
                                      4, 18, 15);

    overflowButtonBreathingView_ = [[TUIView alloc] initWithFrame:overflowFrame];
    overflowButtonBreathingView_.opaque = NO;
    overflowButtonBreathingView_.backgroundColor = [TUIColor clearColor];
    overflowButtonBreathingView_.layout = ^(TUIView *view)
    {
      return CGRectMake(view.superview.bounds.size.width - 16 - 8,
                        4, 18, 15);
    };
    overflowButtonBreathingView_.drawRect = ^(TUIView *view, CGRect rect)
    {
      [[TUIImage imageNamed:@"icon_overflow_green_dark.png" cache:YES] drawAtPoint:CGPointZero];
    };
    overflowButtonBreathingView_.userInteractionEnabled = NO;
    overflowButtonBreathingView_.layer.zPosition = 10000;

    overflowButton_ = [[TUIButton alloc] initWithFrame:overflowFrame];
    [overflowButton_ setImage:[TUIImage imageNamed:@"icon_overflow_active.png" cache:YES]
                     forState:TUIControlStateHighlighted];
    [overflowButton_ setDimsInBackground:NO];
    overflowButton_.autoresizingMask = TUIViewAutoresizingFlexibleLeftMargin;
    overflowButton_.hidden = YES;
    overflowButton_.layer.zPosition = 9999;
    [overflowButton_ addTarget:self
                        action:@selector(overflowButtonAction:)
              forControlEvents:TUIControlEventTouchUpInside];
    [self addSubview:overflowButton_];
    [self updateOverflowButtonAppearance];

    maskView_ = [[TUIView alloc] initWithFrame:self.bounds];
    maskView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    maskView_.opaque = NO;
    maskView_.backgroundColor = [TUIColor clearColor];
    maskView_.drawRect = ^(TUIView *view, CGRect rect) {
      if(tabsView.overflowButton.hidden)
      {
        [[NSColor blackColor] set];
        [NSBezierPath fillRect:view.bounds];
      }
      else
      {
        float marginR = kMVTabsViewOverflowMargin;
        float gradientW = 20;
        NSColor *opaqueColor = [NSColor blackColor];
        NSColor *transparentColor = [NSColor colorWithDeviceWhite:0 alpha:0];
        NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:
                                opaqueColor, 0.0,
                                opaqueColor, 1.0 - ((gradientW + marginR) / rect.size.width),
                                transparentColor, 1.0 - (marginR / rect.size.width),
                                transparentColor, 1.0,
                                nil];
        [gradient drawInRect:rect angle:0];
      }
    };
    contentView_.layer.mask = maskView_.layer;
  }
  return self;
}

#pragma mark -
#pragma mark Overriden Methods

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self updateOverflowButtonVisibility];
}

#pragma mark -
#pragma mark Tabs Management

- (void)addTab:(NSString*)name
      closable:(BOOL)closable
      sortable:(BOOL)sortable
        online:(BOOL)online
    identifier:(NSObject*)identifier
      animated:(BOOL)animated
{
  if([self tabForIdentifier:identifier])
    return;
  MVTabView *tabView = [[MVTabView alloc] initWithFrame:CGRectMake(self.totalWidth, 0, 1, 23)];
  tabView.name = name;
  tabView.identifier = identifier;
  tabView.closable = closable;
  tabView.sortable = sortable;
  tabView.online = online;
  tabView.delegate = self;
  [self.tabs addObject:tabView];
  [self.contentView insertSubview:tabView atIndex:0];

  [tabView.layer setOpacity:0.0];
  if(animated)
    [self mv_performBlock:^{
      [self layoutTabs:animated];
    } afterDelay:0.01];
  else
    [self layoutTabs:animated];

  if([self.delegate respondsToSelector:@selector(tabsViewDidChangeTabs:)])
    [self.delegate tabsViewDidChangeTabs:self];
}

- (void)renameTab:(NSString*)name
   withIdentifier:(NSObject*)identifier
         animated:(BOOL)animated
{
  MVTabView *tabView = [self tabForIdentifier:identifier];
  if(tabView && ![tabView.name isEqualToString:name])
  {
    tabView.name = name;
    [self layoutTabs:animated];
  }
}

- (void)removeTab:(NSObject*)identifier
         animated:(BOOL)animated
{
  MVTabView *tabView = [self tabForIdentifier:identifier];
  if(tabView)
  {
    if(self.selectedTabView == tabView)
    {
      int index = (int)([self.tabs indexOfObject:tabView]);
      [self.tabs removeObject:tabView];

      index++;
      if(index >= self.tabs.count)
        index = self.tabs.count - 1;
      if(self.tabs.count == 0)
      {
        [self setSelectedTab:nil];
      }
      else
      {
        MVTabView *newTabView = [self.tabs objectAtIndex:index];
        [self setSelectedTab:newTabView.identifier];
      }
    }
    else
      [self.tabs removeObject:tabView];


    [TUIView animateWithDuration:kMVTabsViewAnimationDuration animations:^{
      CGRect frame = tabView.layer.frame;
      frame.origin.x += - frame.size.width / 2;
      [tabView.layer setFrame:frame];

      [tabView.layer setOpacity:0.0];

      CATransform3D transform = CATransform3DMakeScale(1 / frame.size.width, 1, 1);
      [tabView.layer setTransform:transform];
    }];
    [self mv_performBlock:^{
      [tabView removeFromSuperview];
    } afterDelay:kMVTabsViewAnimationDuration];
    [self layoutTabs:animated];
    if([self.delegate respondsToSelector:@selector(tabsViewDidChangeTabs:)])
      [self.delegate tabsViewDidChangeTabs:self];
  }
}

- (NSArray*)tabsIdentifiers
{
  NSMutableArray *tabsIdentifiers = [NSMutableArray array];
  MVTabView *tabView;
  for(tabView in self.tabs)
  {
    [tabsIdentifiers addObject:tabView.identifier];
  }
  return tabsIdentifiers;
}

- (int)countTabs
{
  return (int)[self.tabs count];
}

- (void)setGlowing:(BOOL)glowing
        identifier:(NSObject*)identifier
{
  MVTabView *tabView = [self tabForIdentifier:identifier];
  tabView.glowing = glowing;
  int index = (int)[self.tabs indexOfObject:tabView];
  tabView.layer.zPosition = index + (glowing ? 9999 : 0);
  [self updateOverflowButtonAppearance];
  [self updateTabszPositions];
}

- (void)setOnline:(BOOL)online
       identifier:(NSObject*)identifier
{
  MVTabView *tabView = [self tabForIdentifier:identifier];
  tabView.online = online;
}

- (BOOL)hasTabForIdentifier:(NSObject*)identifier
{
  return [self tabForIdentifier:identifier] != nil;
}

#pragma mark -
#pragma mark Selection

- (NSObject*)selectedTab
{
  if(!self.selectedTabView)
    return nil;
  return self.selectedTabView.identifier;
}

- (void)setSelectedTab:(NSObject*)identifier
{
  MVTabView *newSelectedTabView = nil;
  MVTabView *tabView;
  for(tabView in self.tabs) {
    if([tabView.identifier isEqual:identifier]) {
      newSelectedTabView = tabView;
      break;
    }
  }
  if(newSelectedTabView != self.selectedTabView) {
    if(self.selectedTabView) {
      [TUIView animateWithDuration:0.2 animations:^{
        self.selectedTabView.selected = NO;
        [self.selectedTabView redraw];
      }];
    }

    self.selectedTabView = newSelectedTabView;

    if(self.selectedTabView) {
      [TUIView animateWithDuration:0.2 animations:^{
        self.selectedTabView.selected = YES;
        [self.selectedTabView redraw];
      }];
    }

    if([self.delegate respondsToSelector:@selector(tabsViewDidChangeSelection:)])
      [self.delegate tabsViewDidChangeSelection:self];
  }
  [self updateTabszPositions];
}

- (void)selectPreviousTab
{
  if(self.tabs.count <= 0)
    return;
  if(!self.selectedTabView)
    [self setSelectedTab:((MVTabView*)([self.tabs lastObject])).identifier];
  else
  {
    int index = [self.tabs indexOfObject:self.selectedTabView];
    index--;
    if(index < 0)
      index = self.tabs.count - 1;
    [self setSelectedTab:((MVTabView*)([self.tabs objectAtIndex:index])).identifier];
  }
}

- (void)selectNextTab
{
  if(self.tabs.count <= 0)
    return;
  if(!self.selectedTabView)
    [self setSelectedTab:((MVTabView*)([self.tabs objectAtIndex:0])).identifier];
  else
  {
    int index = [self.tabs indexOfObject:self.selectedTabView];
    index++;
    if(index >= self.tabs.count)
      index = 0;
    [self setSelectedTab:((MVTabView*)([self.tabs objectAtIndex:index])).identifier];
  }
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)event onSubview:(TUIView *)subview
{
  [super mouseDown:event onSubview:subview];
  if(![subview isKindOfClass:[MVTabView class]])
    return;

  self.pointWithinTabViewAtMouseDown = [self convertPoint:event.locationInWindow
                                                   toView:subview];
  [self updateTabszPositions];
  self.tabsBeforeReordering = self.tabs.copy;
}

- (void)mouseDragged:(NSEvent *)event onSubview:(TUIView *)subview
{
  [super mouseDragged:event onSubview:subview];
  if(![subview isKindOfClass:[MVTabView class]])
    return;
  MVTabView *tabView = (MVTabView*)subview;
  if(!tabView.sortable)
    return;

  self.sortingTabView = tabView;

  tabView.sorting = YES;

  CGPoint point = [self convertPoint:event.locationInWindow
                              toView:self];
  CGRect frame = tabView.frame;
  frame.origin.x = round(point.x - self.pointWithinTabViewAtMouseDown.x);
  tabView.frame = frame;

  [self reorderTabsFromSortingTabView];
  [self updateTabszPositions];
}

- (void)mouseUp:(NSEvent *)theEvent fromSubview:(TUIView *)subview
{
  [super mouseUp:theEvent fromSubview:(TUIView *)subview];

  if(self.sortingTabView)
  {
    self.sortingTabView.sorting = NO;
    self.sortingTabView = nil;

    [self layoutTabs:YES];
  }
  [self updateTabszPositions];

  if(![self.tabsBeforeReordering isEqualToArray:self.tabs])
  {
    if([self.delegate respondsToSelector:@selector(tabsViewDidChangeOrder:)])
      [self.delegate tabsViewDidChangeOrder:self];
  }
  self.tabsBeforeReordering = nil;
}

#pragma mark -
#pragma mark Buttons Actions

- (void)overflowButtonAction:(id)sender
{
  if(self.menuOpened)
    return;
  NSArray *overflowTabs = [self overflowTabs];
  NSMenu *menu = [[NSMenu alloc] init];
  menu.delegate = self;
  NSMenuItem *menuItem;
  MVTabView *view;
  for(view in overflowTabs)
  {
    menuItem = [[NSMenuItem alloc] initWithTitle:view.name
                                          action:@selector(menuItemAction:)
                                   keyEquivalent:@""];
    if(view.isGlowing)
      menuItem.image = [NSImage imageNamed:@"icon_overflow_menu"];
    menuItem.representedObject = view;
    menuItem.target = self;
    if(view == self.selectedTabView)
      menuItem.state = NSOnState;
    [menu addItem:menuItem];
  }

  if([[menu itemArray] count] <= 0)
    return;
  CGPoint location = [self convertPoint:self.overflowButton.frame.origin
                                 toView:nil];
  location.y -= 8;
  self.menuOpened = YES;
  [menu popUpMenuPositioningItem:nil
                      atLocation:location
                          inView:self.nsView];
}

#pragma mark -
#pragma mark Menu Actions

- (void)menuItemAction:(NSMenuItem*)menuItem
{
  MVTabView *view = menuItem.representedObject;
  [self setSelectedTab:view.identifier];
}

#pragma mark -
#pragma mark Private Methods

- (NSArray*)overflowTabs
{
  NSMutableArray *tabs = [NSMutableArray array];
  MVTabView *view;
  float x = self.bounds.size.width - kMVTabsViewOverflowMargin;
  for(view in self.tabs)
  {
    if(NSMaxX(view.frame) >= x)
    {
      [tabs addObject:view];
    }
  }
  return tabs;
}

- (MVTabView*)tabForIdentifier:(NSObject*)identifier
{
  MVTabView *tabView;
  for(tabView in self.tabs) {
    if([tabView.identifier isEqual:identifier]) {
      return tabView;
    }
  }
  return nil;
}

- (void)updateOverflowButtonVisibility
{
  BOOL newHiddenValue = YES;
  if(self.totalWidth >= self.bounds.size.width)
    newHiddenValue = NO;

  if(newHiddenValue != self.overflowButton.hidden)
  {
    self.overflowButton.hidden = newHiddenValue;
    [self.maskView setNeedsDisplay];
  }
  [self updateOverflowButtonAppearance];
}

- (void)updateOverflowButtonAppearance
{
  NSArray *overflowTabs = self.overflowTabs;
  MVTabView *tab;
  BOOL shouldGlow = NO;
  for(tab in overflowTabs)
  {
    if(tab.isGlowing)
    {
      shouldGlow = YES;
      break;
    }
  }
  if(self.overflowButton.hidden)
    shouldGlow = NO;
  [self.overflowButton setImage:[TUIImage imageNamed:(shouldGlow ?
                                                      @"icon_overflow_green.png" :
                                                      @"icon_overflow.png") cache:YES]
                       forState:TUIControlStateNormal];
  if(shouldGlow)
  {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.values = [NSArray arrayWithObjects:
                        [NSNumber numberWithFloat:0.0],
                        [NSNumber numberWithFloat:1.0],
                        [NSNumber numberWithFloat:0.0],
                        nil];
    animation.repeatCount = INT_MAX;
    animation.duration = 1;
    [self.overflowButtonBreathingView.layer addAnimation:animation
                                                  forKey:@"opacity"];

    if(!self.overflowButtonBreathingView.superview)
      [self addSubview:self.overflowButtonBreathingView];
  }
  else if(self.overflowButtonBreathingView)
  {
    [self.overflowButtonBreathingView removeAllAnimations];
    [self.overflowButtonBreathingView removeFromSuperview];
  }
}

- (void)reorderTabsFromSortingTabView
{
  NSMutableArray *newTabs = [[NSMutableArray alloc] init];
  MVTabView *tabView;
  float x = -1;
  float sortingTabViewX = self.sortingTabView.frame.origin.x +
                          [self.sortingTabView expectedWidth] / 2;
  BOOL foundAPlace = NO;
  for(tabView in self.tabs)
  {
    float w = [tabView expectedWidth];

    if(self.sortingTabView != tabView) {
      if(tabView.sortable && !foundAPlace && sortingTabViewX < x + w / 2) {
        [newTabs addObject:self.sortingTabView];
        foundAPlace = YES;
      }
      [newTabs addObject:tabView];
    }

    x += w - 2;
  }
  if(!foundAPlace)
    [newTabs addObject:self.sortingTabView];

  if(![self.tabs isEqualToArray:newTabs])
  {
    self.tabs = newTabs;
    [self layoutTabs:YES];
  }
}

- (void)layoutTabs:(BOOL)animated
{
  MVTabView *tabView;
  float x = -1;
  int i = 0;
  for(tabView in self.tabs)
  {
    float w = [tabView expectedWidth];

    if(self.sortingTabView != tabView) {
      [TUIView animateWithDuration:kMVTabsViewAnimationDuration animations:^{
        [TUIView setAnimationsEnabled:animated];
        if(tabView.layer.opacity != 1.0)
          [tabView.layer setOpacity:1.0];
        [tabView setFrame:CGRectMake(x, 0, w, 23)];
        [TUIView setAnimationsEnabled:YES];
      }];
    }

    tabView.previousTab = (i == 0 ? nil : [self.tabs objectAtIndex:i-1]);
    tabView.nextTab = ((i + 1 < self.tabs.count) ? [self.tabs objectAtIndex:i+1] : nil);

    x += w - 2;
    i++;
  }
  self.totalWidth = x;
  [self updateOverflowButtonVisibility];
  [self updateTabszPositions];
}

- (void)updateTabszPositions
{
  MVTabView *tabView;
  int i = 0;
  for(tabView in self.tabs)
  {
    tabView.layer.zPosition = (self.tabs.count - i) +
                              (tabView.isSelected ? 150 : 0) +
                              (tabView.isHighlighted ? 100 : 0) +
                              (tabView.isGlowing ? 200 : 0) +
                              (tabView == self.sortingTabView ? 1000 : 0);
    i++;
  }
}

#pragma mark -
#pragma mark MVTabViewDelegate Methods

- (void)tabViewShouldBeSelect:(MVTabView*)tabView
{
  [self setSelectedTab:tabView.identifier];
}

- (void)tabViewShouldBeClose:(MVTabView*)tabView
{
  [self removeTab:tabView.identifier animated:YES];
}

#pragma mark -
#pragma mark NSMenuDelegate Methods

- (void)menuDidClose:(NSMenu *)menu
{
  [self mv_performBlock:^{
    self.menuOpened = NO;
  } afterDelay:0.2];
}

@end
