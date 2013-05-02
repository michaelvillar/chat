#import <TwUI/TUIKit.h>

@class MVTabView;

@protocol MVTabViewDelegate
@optional
- (void)tabViewShouldBeSelect:(MVTabView*)tabView;
- (void)tabViewShouldBeClose:(MVTabView*)tabView;
@end

@interface MVTabView : TUIView

@property (copy, readwrite) NSString *name;
@property (strong, readwrite) NSObject *identifier;
@property (readwrite, nonatomic) BOOL closable;
@property (readwrite) BOOL sortable;
@property (readwrite) BOOL showed;
@property (readwrite, nonatomic, getter = isSelected) BOOL selected;
@property (readonly, getter = isHighlighted) BOOL highlighted;
@property (readwrite, nonatomic) BOOL sorting;
@property (readwrite, getter = isGlowing, nonatomic) BOOL glowing;
@property (readwrite, getter = isOnline, nonatomic) BOOL online;
@property (strong, readwrite, nonatomic) MVTabView *nextTab;
@property (strong, readwrite, nonatomic) MVTabView *previousTab;
@property (weak, readwrite) NSObject <MVTabViewDelegate> *delegate;

- (float)expectedWidth;

@end
