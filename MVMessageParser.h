#import <Foundation/Foundation.h>

@interface MVMessageParser : NSObject

- (NSArray*)parseMessageForURLs:(NSString*)message
                  mentionRanges:(NSSet*)ranges
     fetchServicesAutomatically:(BOOL)fetchServicesAutomatically;

@end
