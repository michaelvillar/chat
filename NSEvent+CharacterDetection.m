#import "NSEvent+CharacterDetection.h"

@implementation NSEvent (CharacterDetection)

- (BOOL)isCharacter:(unichar)aChar {
	return ([[self characters] rangeOfString:[NSString stringWithFormat:@"%C",aChar]].length > 0);
}

- (BOOL)isDigit {
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d"
                                                                         options:0 error:nil];
  NSString *chars = self.characters;
  if(chars.length <= 0)
    return NO;
  NSArray *matches = [regex matchesInString:chars options:0 range:NSMakeRange(0, chars.length)];
  return matches.count > 0;
}

- (BOOL)isChar {
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\w| "
                                                                         options:0 error:nil];
  NSString *chars = self.characters;
  if(chars.length <= 0)
    return NO;
  NSArray *matches = [regex matchesInString:chars options:0 range:NSMakeRange(0, chars.length)];
  return matches.count > 0;
}

@end
