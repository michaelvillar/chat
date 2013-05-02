
#import "NSString+QueryParsing.h"

@implementation NSString (QueryParsing)

- (NSString *)stringByDecodingURLFormat
{
  NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return result;
}

- (NSString *)stringByEncodingURLFormat
{
  NSString *result = [self stringByReplacingOccurrencesOfString:@" " withString:@"+"];
  result = [result stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return result;
}

- (NSMutableDictionary *)dictionaryFromQueryComponents
{
  NSMutableDictionary *queryComponents = [NSMutableDictionary dictionary];
  for(NSString *keyValuePairString in [self componentsSeparatedByString:@"&"])
  {
    NSArray *keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
    // Verify that there is at least one key, and at least one value.  Ignore extra = signs
    if ([keyValuePairArray count] < 2)
      continue;
    NSString *key = [[keyValuePairArray objectAtIndex:0] stringByDecodingURLFormat];
    NSString *value = [[keyValuePairArray objectAtIndex:1] stringByDecodingURLFormat];
    // URL spec says that multiple values are allowed per key
    NSMutableArray *results = [queryComponents objectForKey:key];
    // First object
    if(!results)
    {
      results = [NSMutableArray arrayWithCapacity:1];
      [queryComponents setObject:results forKey:key];
    }
    [results addObject:value];
  }
  return queryComponents;
}

@end
