#define kMVTitleBarHeight 24

@class MVWindowTitleBarView;

@interface MVWindow : NSWindow

@property (strong, readonly) MVWindowTitleBarView *titleBarView;

@end
