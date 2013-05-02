#import "MVGetRedirectedURL.h"

@interface MVGetRedirectedURL () <NSURLConnectionDelegate>

@property (strong, readwrite) NSURL *url;
@property (strong, readwrite) NSURLRequest *urlRequest;
@property (strong, readwrite) NSURLConnection *urlConnection;
@property (strong, readwrite) void(^callbackBlock)(NSURL *redirectedURL, NSString *suggestedFilename);

@end

@implementation MVGetRedirectedURL

@synthesize url               = url_,
            urlRequest        = urlRequest_,
            urlConnection     = urlConnection_,
            callbackBlock     = callbackBlock_;

- (id)initWithURL:(NSURL*)url
{
  self = [super init];
  if(self)
  {
    url_ = url;
    urlRequest_ = nil;
    urlConnection_ = nil;
    callbackBlock_ = nil;
  }
  return self;
}

- (void)get:(void(^)(NSURL *redirectedURL, NSString *suggestedFilename))block
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.url];
    [req setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [req setHTTPMethod:@"GET"];

    self.urlRequest = req;
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:req
                                                         delegate:self];
    if (!self.urlConnection)
    {
      block(nil, nil);
    }
    else
    {
      self.callbackBlock = block;
      CFRunLoopRun();
    }
  });
}

#pragma mark -
#pragma mark NSURLConnectionDelegate Methods

- (NSURLRequest *)connection:(NSURLConnection *)inConnection
             willSendRequest:(NSURLRequest *)inRequest
            redirectResponse:(NSURLResponse *)inRedirectResponse;
{
  if(inRedirectResponse)
  {
    NSMutableURLRequest *req = self.urlRequest.mutableCopy;
    req.URL = inRequest.URL;
    self.urlRequest = req;
    return req;
  }
  return inRequest;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.callbackBlock(nil, nil);
  });
	CFRunLoopStop(CFRunLoopGetCurrent());
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [self.urlConnection cancel];
  dispatch_async(dispatch_get_main_queue(), ^{
    self.callbackBlock(self.urlRequest.URL, response.suggestedFilename);
  });
  CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
  return nil;
}

@end
