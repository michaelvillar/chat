#import <TwUI/TUIKit.h>

#define kMVActivityIndicatorStyleNormal 1
#define kMVActivityIndicatorStyleBlue 2
#define kMVActivityIndicatorStyleBottomBar 3

@interface MVActivityIndicatorView : TUIView

@property (readwrite) int style;

- (void)startAnimating;
- (void)stopAnimating;

@end
