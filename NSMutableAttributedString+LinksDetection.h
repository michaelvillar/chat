#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (LinksDetection)

- (void)mv_detectLinks;
- (void)mv_detectEmails;
- (void)mv_detectTwitterUsernamesAndHashTags;

@end
