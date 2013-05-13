#import "MVFileUpload.h"
#import "MVUploadAuthorization.h"
#import "MVFileUpload_Private.h"

#define kMVFileUploadSuccessStatusCode 200

@interface MVFileUpload ()

- (void)addValue:(NSString*)value
          forKey:(NSString*)aKey
      toPostBody:(NSMutableData*)postBody
  stringBoundary:(NSString*)stringBoundary;

@end

@implementation MVFileUpload

@synthesize key                         = key_,
            data                        = data_,
            operationQueue              = operationQueue_,
            urlConnection               = urlConnection_,
            mutableData                 = mutableData_,
            statusCode                  = statusCode_,
            uploadAuthorization         = uploadAuthorization_,
            uploadPercentage            = uploadPercentage_,
            finished                    = finished_,
            error                       = error_,
            remoteURL                   = remoteURL_,
            remoteURLForAsset           = remoteURLForAsset_,
            delegate                    = delegate_;

- (id)initWithKey:(NSString*)key
             data:(NSData*)data
   operationQueue:(NSOperationQueue*)operationQueue
uploadAuthorization:(MVUploadAuthorization*)uploadAuthorization
{
  self = [super init];
  if(self)
  {
    key_ = key;
    data_ = data;
    operationQueue_ = operationQueue;
    urlConnection_ = nil;
    mutableData_ = nil;
    statusCode_ = -1;
    uploadAuthorization_ = uploadAuthorization;
    uploadPercentage_ = 0;
    finished_ = NO;
    error_ = NO;
    remoteURL_ = nil;
    remoteURLForAsset_ = nil;
    delegate_ = nil;
  }
  return self;
}

- (void)start
{
  NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    if([self.delegate respondsToSelector:@selector(fileUploadShouldStart:)])
    {
      if(![self.delegate fileUploadShouldStart:self])
        return;
    }

		/*
		 * Init URL connection and start uploading the file
		 */
		NSURL *url = [NSURL URLWithString:self.uploadAuthorization.uploadURL];

		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
		[req setHTTPMethod:@"POST"];

		//Add the header info
		NSString *stringBoundary = @"0xKhTmLbOuNdArY";
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",
                             stringBoundary];
		[req addValue:contentType forHTTPHeaderField:@"Content-Type"];

		// create the body
		NSMutableData *postBody = [NSMutableData data];

		// add key
		[self addValue:self.key
            forKey:@"key"
        toPostBody:postBody
		stringBoundary:stringBoundary];

		[self addValue:self.uploadAuthorization.successActionRedirect
            forKey:@"success_action_redirect"
        toPostBody:postBody
		stringBoundary:stringBoundary];

		[self addValue:self.uploadAuthorization.policy
            forKey:@"policy"
        toPostBody:postBody
		stringBoundary:stringBoundary];

		[self addValue:self.uploadAuthorization.signature
            forKey:@"signature"
        toPostBody:postBody
		stringBoundary:stringBoundary];

		[self addValue:self.uploadAuthorization.accessKeyId
            forKey:@"AWSAccessKeyId"
        toPostBody:postBody
		stringBoundary:stringBoundary];

		[self addValue:self.uploadAuthorization.acl
            forKey:@"acl"
        toPostBody:postBody
		stringBoundary:stringBoundary];

		// append file data
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary]
                          dataUsingEncoding:NSUTF8StringEncoding]];

		NSString *line = [NSString stringWithFormat:@"Content-Disposition: form-data; \
                      name=\"file\"; filename=\"%@\"\r\n",[self.key lastPathComponent]];
		[postBody appendData:[line dataUsingEncoding:NSUTF8StringEncoding]];
		line = @"Content-Type: application/octet-stream\r\n";
		[postBody appendData:[line dataUsingEncoding:NSASCIIStringEncoding]];
		line = @"Content-Transfer-Encoding: binary\r\n\r\n";
		[postBody appendData:[line dataUsingEncoding:NSASCIIStringEncoding]];
		[postBody appendData:self.data];
		line = [NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary];
		[postBody appendData:[line dataUsingEncoding:NSUTF8StringEncoding]];

		//add the body to the post
		[req setHTTPBody:postBody];

    self.mutableData = [NSMutableData data];
		self.urlConnection = [NSURLConnection connectionWithRequest:req
                                                       delegate:self];
		if (!self.urlConnection)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
          [self.delegate fileUpload:self didFailWithError:nil];
      });
		}
		else
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        if([self.delegate respondsToSelector:@selector(fileUploadDidStart:)])
          [self.delegate fileUploadDidStart:self];
      });
      CFRunLoopRun();
    }
	}];
	[self.operationQueue addOperation:operation];
}

#pragma mark -
#pragma mark Private Methods

- (void)addValue:(NSString*)value
          forKey:(NSString*)aKey
      toPostBody:(NSMutableData*)postBody
  stringBoundary:(NSString*)stringBoundary
{
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary]
                        dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; \
                         name=\"%@\"\r\n\r\n",aKey] dataUsingEncoding:NSASCIIStringEncoding]];
	[postBody appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
      [self.delegate fileUpload:self didFailWithError:error];
    self.error = YES;
  });
	CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.mutableData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	float percent = (100*(float)totalBytesWritten/(float)totalBytesExpectedToWrite);
  self.uploadPercentage = percent;
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileUpload:didProgress:)])
      [self.delegate fileUpload:self didProgress:percent];
  });
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
	self.statusCode = [httpResponse statusCode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSError *error = nil;
  NSObject *json = [NSJSONSerialization JSONObjectWithData:self.mutableData
                                                   options:0
                                                     error:&error];

	if(self.statusCode == kMVFileUploadSuccessStatusCode && !error)
  {
    NSString *hrefString = [json valueForKey:@"href"];
    self.remoteURLForAsset = self.remoteURL = [NSURL URLWithString:hrefString];

    if(self.uploadPercentage != 100)
    {
      self.uploadPercentage = 100;
    }

    self.finished = YES;

		dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(fileUploadDidFinish:)])
        [self.delegate fileUploadDidFinish:self];
    });
	}
  else
  {
    NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:
                                               @"StatusCode (%li) should be %i",
                                               (long)(self.statusCode),
                                               kMVFileUploadSuccessStatusCode]
                                         code:self.statusCode
                                     userInfo:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
        [self.delegate fileUpload:self didFailWithError:error];
      self.error = YES;
    });
  }
	CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
