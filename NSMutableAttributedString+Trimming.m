#import "NSMutableAttributedString+Trimming.h"

@implementation NSMutableAttributedString (Trimming)

- (void)mv_trimWhiteSpaces
{
  [self beginEditing];

  NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@" \n"];

  // First clear from the beginning of the string
  NSRange range = [self.string rangeOfCharacterFromSet:set];
  while (range.length != 0 && range.location == 0)
  {
    [self replaceCharactersInRange:range withString:@""];
    range = [self.string rangeOfCharacterFromSet:set];
  }

  // Then clear from the end of the string
  range = [self.string rangeOfCharacterFromSet:set
                                       options:NSBackwardsSearch];
  while (range.length != 0 && NSMaxRange(range) == self.string.length)
  {
    [self replaceCharactersInRange:range withString:@""];
    range = [self.string rangeOfCharacterFromSet:set
                                         options:NSBackwardsSearch];
  }

  [self endEditing];
}

@end
