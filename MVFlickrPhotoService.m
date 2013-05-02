#import "MVFlickrPhotoService.h"
#import "MVJSONGetRequest.h"

#define kMVFlickrAPIKey @"4e41bc0965b8a101fabf5b63c72db069"

@interface MVFlickrPhotoService ()

@property (strong, readwrite) NSURL *url;
@property (readwrite) long long photoId;
@property (strong, readwrite) NSString *title;
@property (strong, readwrite) NSURL *imageUrl;
@property (readwrite) BOOL informationFetched;
@property (readwrite) BOOL error;

@end

@implementation MVFlickrPhotoService

@synthesize url                 = url_,
            photoId             = photoId_,
            title               = title_,
            imageUrl            = imageUrl_,
            informationFetched  = informationFetched_,
            error               = error_;

- (id)initWithURL:(NSURL*)url
          photoId:(long long)photoId
{
  self = [super init];
  if(self)
  {
    url_ = url;
    photoId_ = photoId;
    title_ = nil;
    imageUrl_ = nil;
    informationFetched_ = NO;
    error_ = NO;
  }
  return self;
}

#pragma mark -
#pragma mark MVService Methods

- (void)fetchInformation
{
  NSString *urlString = [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=%@&photo_id=%lld&format=json&nojsoncallback=1",
                         kMVFlickrAPIKey, self.photoId];
  NSURL *url = [NSURL URLWithString:urlString];
  MVJSONGetRequest *getRequest = [[MVJSONGetRequest alloc] initWithURL:url];
  [getRequest get:^(NSObject *object) {
    @try {
      NSDictionary *dictionary = (NSDictionary*)object;
      if(dictionary && [dictionary valueForKey:@"photo"])
      {
        NSDictionary *photo = [dictionary valueForKey:@"photo"];
        self.title = [[photo valueForKey:@"title"] valueForKey:@"_content"];

        NSString *farm = [photo valueForKey:@"farm"];
        NSString *server = [photo valueForKey:@"server"];
        NSString *secret = [photo valueForKey:@"secret"];
        NSString *imageUrlString = [NSString stringWithFormat:
                                    @"http://farm%@.staticflickr.com/%@/%lld_%@.jpg",
                                    farm, server, self.photoId, secret];
        self.imageUrl = [NSURL URLWithString:imageUrlString];
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
}

+ (MVFlickrPhotoService*)serviceForURL:(NSURL*)url;
{
  if([url.host isEqualToString:@"flickr.com"] || [url.host isEqualToString:@"www.flickr.com"])
  {
    NSString *pattern = @"\\/photos\\/.[^\\/]*\\/([0-9]*)\\/?";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                        options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:url.path
                                      options:0
                                        range:NSMakeRange(0, url.path.length)];

    if(matches.count == 1)
    {
      NSTextCheckingResult *match = [matches objectAtIndex:0];
      NSRange photoIdRange = [match rangeAtIndex:1];
      long long photoId = [[url.path substringWithRange:photoIdRange] longLongValue];
      if(photoId == 0)
        return nil;
      MVFlickrPhotoService *service = [[MVFlickrPhotoService alloc] initWithURL:url
                                                                          photoId:photoId];
      return service;
    }
  }
  return nil;
}

@end