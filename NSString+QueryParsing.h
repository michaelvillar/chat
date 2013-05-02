
#import <Foundation/Foundation.h>

@interface NSString (QueryParsing)
- (NSString *)stringByDecodingURLFormat;
- (NSString *)stringByEncodingURLFormat;
- (NSMutableDictionary *)dictionaryFromQueryComponents;
@end
