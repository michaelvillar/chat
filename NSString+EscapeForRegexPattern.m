
#import "NSString+EscapeForRegexPattern.h"

@implementation NSString (EscapeForRegexPattern)

- (NSString*)mv_escapeForRegexPattern
{
  NSString *string = self;
  string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
  string = [string stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
  string = [string stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
  string = [string stringByReplacingOccurrencesOfString:@"*" withString:@"\\*"];
  string = [string stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
  string = [string stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
  string = [string stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
  string = [string stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
  string = [string stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
  string = [string stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
  string = [string stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
  string = [string stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
  string = [string stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
  string = [string stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
  return string;
}

@end
