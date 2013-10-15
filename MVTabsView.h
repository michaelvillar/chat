#import <TwUI/TUIKit.h>
#import "MVTopBarView.h"

@class MVTabsView;

@protocol MVTabsViewDelegate
@optional
- (void)tabsViewDidChangeSelection:(MVTabsView*)tabsView;
- (void)tabsViewDidChangeTabs:(MVTabsView*)tabsView;
- (void)tabsViewDidChangeOrder:(MVTabsView*)tabsView;
@end

@interface MVTabsView : TUIView

@property (weak, readwrite) NSObject <MVTabsViewDelegate> *delegate;

#pragma mark -
#pragma mark Tabs Management
- (void)addTab:(NSString*)name
      closable:(BOOL)closable
      sortable:(BOOL)sortable
        online:(BOOL)online
    identifier:(NSObject*)identifier
      animated:(BOOL)animated;
- (void)addTab:(NSString*)name
      closable:(BOOL)closable
      sortable:(BOOL)sortable
        online:(BOOL)online
    identifier:(NSObject*)identifier
       atIndex:(NSUInteger)index
      animated:(BOOL)animated;
- (void)renameTab:(NSString*)name
   withIdentifier:(NSObject*)identifier
         animated:(BOOL)animated;
- (void)removeTab:(NSObject*)identifier
         animated:(BOOL)animated;
- (NSArray*)tabsIdentifiers;
- (int)countTabs;
- (void)setGlowing:(BOOL)glowing
        identifier:(NSObject*)identifier;
- (void)setOnline:(BOOL)online
       identifier:(NSObject*)identifier;
- (BOOL)hasTabForIdentifier:(NSObject*)identifier;

#pragma mark -
#pragma mark Selection
- (NSObject*)selectedTab;
- (void)setSelectedTab:(NSObject*)identifier;
- (void)selectPreviousTab;
- (void)selectNextTab;

@end
