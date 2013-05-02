#import "MVURLKit.h"
#import "MVMessageParser.h"
#import "MVMessage.h"
#import "MVService.h"
#import "MVDribbbleShotService.h"
#import "MVTwitterTweetService.h"
#import "MVYoutubeVideoService.h"
#import "MVCloudAppLinkService.h"
#import "MVVimeoVideoService.h"
#import "MVFlickrPhotoService.h"
#import "MVImageService.h"
#import "MVDroplrLinkService.h"
#import "NSMutableAttributedString+LinksDetection.h"
#import "NSMutableAttributedString+Trimming.h"

@interface MVMessageParser ()

- (NSObject<MVService>*)serviceForURL:(NSURL*)url;

@end

@implementation MVMessageParser

- (NSArray*)parseMessageForURLs:(NSString*)message
                  mentionRanges:(NSSet*)ranges
     fetchServicesAutomatically:(BOOL)fetchServicesAutomatically
{
  if(!message)
    return [NSArray array];
  NSMutableArray *messages = [NSMutableArray array];
  __block NSMutableAttributedString *lastAttributedString =
                                              [[NSMutableAttributedString alloc] init];
  NSMutableAttributedString *attributedMessage =
                                [[NSMutableAttributedString alloc] initWithString:message];
  NSRange stringRange = NSMakeRange(0, message.length);
  NSValue *range;
  for(range in ranges)
  {
    [attributedMessage addAttribute:kMVMentionAttributeName
                              value:@"YES"
                              range:NSIntersectionRange([range rangeValue],
                                                        stringRange)];
  }
  [attributedMessage mv_detectLinks];
  [attributedMessage mv_detectEmails];
  [attributedMessage enumerateAttribute:NSLinkAttributeName
                                inRange:NSMakeRange(0, attributedMessage.length)
                                options:0
                             usingBlock:^(id value, NSRange enumeratedRange, BOOL *stop)
  {
    BOOL appendAttributedString = YES;
    if(value && [value isKindOfClass:[NSURL class]])
    {
      NSURL *url = (NSURL*)value;
      NSObject<MVService>* service = [self serviceForURL:url];
      if(service)
      {
        [lastAttributedString mv_trimWhiteSpaces];
        if(lastAttributedString.length > 0)
        {
          MVMessage *message = [[MVMessage alloc] initWithAttributedString:lastAttributedString];
          [messages addObject:message];
          lastAttributedString = [[NSMutableAttributedString alloc] init];
        }
        if(fetchServicesAutomatically)
          [service fetchInformation];
        MVMessage *message = [[MVMessage alloc] initWithAttributedString:[attributedMessage
                                                    attributedSubstringFromRange:enumeratedRange]
                                                                   service:service];
        [messages addObject:message];
        appendAttributedString = NO;
      }
    }
    if(appendAttributedString)
    {
      [lastAttributedString appendAttributedString:
                        [attributedMessage attributedSubstringFromRange:enumeratedRange]];
    }
  }];
  [lastAttributedString mv_trimWhiteSpaces];
  if(lastAttributedString.length > 0)
  {
    MVMessage *message = [[MVMessage alloc] initWithAttributedString:lastAttributedString];
    [messages addObject:message];
  }
  return messages;
}

- (NSObject<MVService>*)serviceForURL:(NSURL*)url
{
  NSObject<MVService>* service;
  NSArray *serviceClassnames = [NSArray arrayWithObjects:
                                @"MVDribbbleShotService",
                                @"MVTwitterTweetService",
                                @"MVYoutubeVideoService",
                                @"MVCloudAppLinkService",
                                @"MVDroplrLinkService",
                                @"MVVimeoVideoService",
                                @"MVFlickrPhotoService",
                                @"MVImageService",
                                nil];
  NSString *serviceClassname;
  for(serviceClassname in serviceClassnames)
  {
    service = [NSClassFromString(serviceClassname) serviceForURL:url];
    if(service)
      return service;
  }
  return nil;
}

@end
