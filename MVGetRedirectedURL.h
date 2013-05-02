#import <Foundation/Foundation.h>

@interface MVGetRedirectedURL : NSObject

@property (strong, readonly) NSURL *url;

- (id)initWithURL:(NSURL*)url;
- (void)get:(void(^)(NSURL *redirectedURL, NSString *suggestedFilename))block;

@end
