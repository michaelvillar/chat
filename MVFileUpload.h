#import <Foundation/Foundation.h>

@class MVFileUpload,
       MVUploadAuthorization;

@protocol MVFileUploadDelegate
@optional
- (BOOL)fileUploadShouldStart:(MVFileUpload*)fileUpload;
- (void)fileUploadDidStart:(MVFileUpload*)fileUpload;
- (void)fileUpload:(MVFileUpload*)fileUpload
       didProgress:(float)percent;
- (void)fileUploadDidFinish:(MVFileUpload*)fileUpload;
- (void)fileUpload:(MVFileUpload*)fileUpload
  didFailWithError:(NSError*)error;
@end

@interface MVFileUpload : NSObject

@property (strong, readonly) NSString *key;
@property (strong, readonly) NSData *data;
@property (strong, readonly) NSOperationQueue *operationQueue;
@property (strong, readwrite) MVUploadAuthorization *uploadAuthorization;
@property (readonly) float uploadPercentage;
@property (readonly, getter = isFinished) BOOL finished;
@property (readonly, getter = isError) BOOL error;
@property (strong, readonly) NSURL *remoteURL;
@property (strong, readonly) NSURL *remoteURLForAsset;
@property (weak, readwrite) NSObject <MVFileUploadDelegate> *delegate;

- (id)initWithKey:(NSString*)key
             data:(NSData*)data
   operationQueue:(NSOperationQueue*)operationQueue
uploadAuthorization:(MVUploadAuthorization*)uploadAuthorization;
- (void)start;

@end
