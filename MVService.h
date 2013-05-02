#import <Foundation/Foundation.h>

@protocol MVService

@property (strong, readonly) NSURL *url;
@property (readonly) BOOL informationFetched;
@property (readonly) BOOL error;

+ (NSObject<MVService>*)serviceForURL:(NSURL*)url;
- (void)fetchInformation;

@end
