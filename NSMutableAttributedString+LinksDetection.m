#import "NSMutableAttributedString+LinksDetection.h"

@implementation NSMutableAttributedString (LinksDetection)

- (void)mv_detectLinks
{
  [self beginEditing];
  NSError *error = nil;
  NSString *pattern = @"((?:https?:\\/\\/|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}\\/)(?:[^\\s()<>\
  ]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!(\
  )\\[\\]{};:'\".,<>?«»“”‘’]))";
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:pattern
                                options:NSRegularExpressionCaseInsensitive
                                error:&error];
  if(regex)
  {
    NSArray *matches = [regex matchesInString:self.string
                                      options:0
                                        range:NSMakeRange(0, [self length])];
    NSTextCheckingResult *match;
    NSString *string = [NSString stringWithString:[self string]];
    NSString *urlString;
    NSURL *url;
    NSRange matchRange;
    NSString *label;
    int offset = 0;
    for (match in matches)
    {
      matchRange = [match range];
      urlString = [string substringWithRange:matchRange];
      label = [NSString stringWithString:urlString];
      if([label length] >= 7 && [[label substringToIndex:7] isEqualToString:@"http://"])
        label = [label substringFromIndex:7];
      if([label length] >= 1 && [[label substringFromIndex:[label length] - 1] isEqualToString:@"/"])
        label = [label substringToIndex:[label length] - 1];

      if([urlString length] < 8 || (![[urlString substringToIndex:7] isEqualToString:@"http://"] &&
                                    ![[urlString substringToIndex:8] isEqualToString:@"https://"]))
      {
        urlString = [NSString stringWithFormat:@"http://%@",urlString];
      }

      url = [NSURL URLWithString:urlString];
      if(!url)
        url = [NSURL URLWithString:
               [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
      if(url)
      {
        matchRange.location -= offset;
        [self replaceCharactersInRange:matchRange withString:label];
        offset += matchRange.length - [label length];
        matchRange.length = [label length];

        [self addAttribute:NSLinkAttributeName
                       value:url
                       range:matchRange];
      }
    }
  }
  [self endEditing];
}

- (void)mv_detectEmails
{
  [self beginEditing];
  NSError *error = nil;
  NSString *pattern = @"^(|.+ )([A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4})(|.+ )$";
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:pattern
                                options:NSRegularExpressionCaseInsensitive
                                error:&error];
  if(regex)
  {
    NSArray *matches = [regex matchesInString:self.string
                                      options:0
                                        range:NSMakeRange(0, [self length])];
    NSTextCheckingResult *match;
    NSString *string = [NSString stringWithString:[self string]];
    NSString *emailString;
    NSURL *url;
    NSRange matchRange;
    for (match in matches)
    {
      matchRange = [match range];
      emailString = [string substringWithRange:matchRange];
      url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@",emailString]];
      if(url)
      {
        [self addAttribute:NSLinkAttributeName
                     value:url
                     range:matchRange];
      }
    }
  }
  [self endEditing];
}

- (void)mv_detectTwitterUsernamesAndHashTags
{
  [self beginEditing];
  NSTextCheckingResult *match;
  NSRange matchRange;
  NSRange usernameRange;
  NSString *username;
  NSString *hashTag;
  NSURL *url;

  NSError *error = nil;
  NSString *pattern = @"@{1}([-A-Za-z0-9_]{2,})";
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:pattern
                                options:NSRegularExpressionCaseInsensitive
                                error:&error];
  if(regex)
  {
    NSArray *matches = [regex matchesInString:self.string
                                      options:0
                                        range:NSMakeRange(0, [self length])];
    for (match in matches)
    {
      matchRange = [match range];
      usernameRange = [match rangeAtIndex:1];
      username = [self.string substringWithRange:usernameRange];
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/%@",username]];
      if(url)
        [self addAttribute:NSLinkAttributeName
                     value:url
                     range:matchRange];
    }
  }

  pattern = @"[\\s]{1,}#{1}([^\\s]{2,})";
  regex = [NSRegularExpression
           regularExpressionWithPattern:pattern
           options:NSRegularExpressionCaseInsensitive
           error:&error];
  if(regex)
  {
    NSArray *matches = [regex matchesInString:self.string
                                      options:0
                                        range:NSMakeRange(0, [self length])];
    for (match in matches)
    {
      matchRange = [match range];
      hashTag = [self.string substringWithRange:[match rangeAtIndex:1]];
      url = [NSURL URLWithString:
             [NSString stringWithFormat:@"http://twitter.com/search/%@",
              [[NSString stringWithFormat:@"#%@",hashTag]
               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
      if(url)
        [self addAttribute:NSLinkAttributeName
                     value:url
                     range:matchRange];
    }
  }
}

@end
