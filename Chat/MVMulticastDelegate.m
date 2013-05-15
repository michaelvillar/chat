#import "MVMulticastDelegate.h"

@interface MVMulticastDelegateItem : NSObject
@property (weak, readwrite) id delegate;
@end

@implementation MVMulticastDelegateItem

@synthesize delegate = delegate_;

- (id)initWithDelegate:(id)delegate
{
  self = [super init];
  if(self)
  {
    delegate_ = delegate;
  }
  return self;
}

@end

@interface MVMulticastDelegate ()
@property (strong, readwrite) NSMutableSet *delegates;
@end

@implementation MVMulticastDelegate

@synthesize delegates = delegates_;

- (id)init
{
  self = [super init];
  if(self)
  {
    delegates_ = [NSMutableSet set];
  }
  return self;
}

- (void)addDelegate:(id)delegate
{
  MVMulticastDelegateItem *item = [[MVMulticastDelegateItem alloc] initWithDelegate:delegate];
  [self.delegates addObject:item];
}

- (void)removeDelegate:(id)delegate
{
  NSSet *delegatesCopy = self.delegates.copy;
  for(MVMulticastDelegateItem *item in delegatesCopy)
  {
    if(item.delegate == delegate)
      [self.delegates removeObject:item];
  }
}

- (void)forwardInvocation:(NSInvocation *)origInvocation
{
	SEL selector = [origInvocation selector];	
	for (MVMulticastDelegateItem *item in self.delegates)
	{
    id delegate = item.delegate;
    
		if ([delegate respondsToSelector:selector])
		{
      [origInvocation invokeWithTarget:delegate];
		}
	}
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
	// Prevent NSInvalidArgumentException
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	for (MVMulticastDelegateItem *item in self.delegates)
	{
    id delegate = item.delegate;
		
		NSMethodSignature *result = [delegate methodSignatureForSelector:aSelector];
		
		if (result != nil)
		{
			return result;
		}
	}
	
	// This causes a crash...
	// return [super methodSignatureForSelector:aSelector];
	
	// This also causes a crash...
	// return nil;
	
	return [[self class] instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)doNothing {}

@end
