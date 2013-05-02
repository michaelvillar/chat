#import <Foundation/Foundation.h>

@class MVFileDownload;

@protocol MVFileDownloadDelegate
@optional
- (void)fileDownloadDidStart:(MVFileDownload*)fileDownload;
- (void)fileDownload:(MVFileDownload*)fileDownload
         didProgress:(float)percent;
- (void)fileDownloadDidFinish:(MVFileDownload*)fileDownload;
- (void)fileDownload:(MVFileDownload*)fileDownload
    didFailWithError:(NSError*)error;
@end

@interface MVFileDownload : NSObject

@property (strong, readonly) NSURL *sourceURL;
@property (strong, readonly) NSURL *destinationURL;
@property (readonly) float downloadPercentage;
@property (readonly, getter = isFinished) BOOL finished;
@property (readonly, getter = isError) BOOL error;
@property (strong, readonly) NSOperationQueue *operationQueue;
@property (weak, readwrite) NSObject <MVFileDownloadDelegate> *delegate;

- (id)initWithSourceURL:(NSURL*)sourceURL
         destinationURL:(NSURL*)destinationURL
         operationQueue:(NSOperationQueue*)operationQueue;
- (void)start;

@end
