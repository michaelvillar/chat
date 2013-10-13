#import "TUIView+Easing.h"

@interface TUIViewAnimation

@property (nonatomic, strong, readonly) CABasicAnimation *basicAnimation;

@end

@interface TUIView ()
+ (TUIViewAnimation *)_currentAnimation;
@end

@implementation TUIView (Easing)

+ (void)setEasing:(CAMediaTimingFunction*)timingFunction
{
	[self _currentAnimation].basicAnimation.timingFunction = timingFunction;
}

@end
