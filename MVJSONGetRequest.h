#import <Foundation/Foundation.h>

@interface MVJSONGetRequest : NSObject

@property (strong, readonly) NSURL *url;

- (id)initWithURL:(NSURL*)url;
- (void)get:(void(^)(NSObject *json))block;

@end
