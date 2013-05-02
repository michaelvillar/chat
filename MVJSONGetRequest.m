#import "MVJSONGetRequest.h"

@interface MVJSONGetRequest () <NSURLConnectionDelegate>

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSURLConnection *urlConnection;
@property (strong, readwrite) NSMutableData *mutableData;
@property (strong, readwrite) void(^callbackBlock)(NSObject *json);

@end

@implementation MVJSONGetRequest

@synthesize url               = url_,
            urlConnection     = urlConnection_,
            mutableData       = mutableData_,
            callbackBlock     = callbackBlock_;

- (id)initWithURL:(NSURL*)url
{
  self = [super init];
  if(self)
  {
    url_ = url;
    urlConnection_ = nil;
    mutableData_ = nil;
    callbackBlock_ = nil;
  }
  return self;
}

- (void)get:(void(^)(NSObject *json))block
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.url];
    [req setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [req setHTTPMethod:@"GET"];
    [req setAllHTTPHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"application/json", @"Accept",
                                 nil]];

    self.urlConnection = [[NSURLConnection alloc] initWithRequest:req
                                                         delegate:self];
    if (!self.urlConnection)
    {
      block(nil);
    }
    else
    {
      self.callbackBlock = block;
      self.mutableData = [[NSMutableData alloc] init];
      CFRunLoopRun();
    }
  });
}

#pragma mark -
#pragma mark NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.callbackBlock(nil);
  });
	CFRunLoopStop(CFRunLoopGetCurrent());
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.mutableData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSError *error = nil;
  NSObject *json = [NSJSONSerialization JSONObjectWithData:self.mutableData
                                                   options:0
                                                     error:&error];
  dispatch_async(dispatch_get_main_queue(), ^{
    self.callbackBlock(json);
  });
  CFRunLoopStop(CFRunLoopGetCurrent());
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
  return nil;
}

@end
