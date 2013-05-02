#import "MVDroplrLinkService.h"
#import "MVGetRedirectedURL.h"
#import "NSString+QueryParsing.h"

@interface MVDroplrLinkService ()

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSString *itemType;
@property (strong, readwrite) NSURL *downloadUrl;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVDroplrLinkService

@synthesize url                 = url_,
            itemType            = itemType_,
            downloadUrl         = downloadUrl_,
            informationFetched  = informationFetched_,
            error               = error_;

- (id)initWithURL:(NSURL*)url
         itemType:(NSString*)type
{
  self = [super init];
  if(self)
  {
    url_ = url;
    itemType_ = type;
    downloadUrl_ = nil;
    informationFetched_ = NO;
    error_ = NO;
  }
  return self;
}

- (BOOL)isImage
{
  return [self.itemType isEqualToString:@"i"];
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    NSURL *shortURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@+",self.url.absoluteString]];
    MVGetRedirectedURL *getRedirectedURL = [[MVGetRedirectedURL alloc] initWithURL:shortURL];
    [getRedirectedURL get:^(NSURL *redirectedURL, NSString *suggestedFilename) {
      @try {
        if(redirectedURL)
        {
          suggestedFilename = [suggestedFilename stringByAddingPercentEscapesUsingEncoding:
                               NSUTF8StringEncoding];
          self.downloadUrl = [NSURL URLWithString:
                              [NSString stringWithFormat:@"%@+#chat_filename=%@",
                                                         self.url.absoluteString,
                                                         suggestedFilename]];
        }
        else
        {
          self.error = YES;
        }
      }
      @catch (NSException *exception) {
        self.error = YES;
      }

      self.informationFetched = YES;
    }];
  });
}

+ (MVDroplrLinkService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"d.pr"])
  {
    if(url.pathComponents.count >= 2)
    {
      NSSet *availableTypes = [NSSet setWithObjects:@"n", @"a", @"v", @"i", @"f", nil];
      NSString *type = ([[url.pathComponents objectAtIndex:0] isEqualToString:@"/"] ?
                        [url.pathComponents objectAtIndex:1] :
                        [url.pathComponents objectAtIndex:0]);
      if(type && [availableTypes containsObject:type])
      {
        MVDroplrLinkService *service = [[MVDroplrLinkService alloc] initWithURL:url
                                                                         itemType:type];
        return service;
      }
    }
  }
  return nil;
}

@end
