#import <Foundation/Foundation.h>

@interface NSObject (PerformBlockAfterDelay)

- (void)mv_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

@end
