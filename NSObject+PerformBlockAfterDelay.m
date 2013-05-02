#import "NSObject+PerformBlockAfterDelay.h"

@implementation NSObject (PerformBlockAfterDelay)

- (void)mv_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
  dispatch_queue_t queue = ([NSThread isMainThread] ?
                            dispatch_get_main_queue() :
                            dispatch_get_current_queue());
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC),
                 queue,
                 block);
}

@end
