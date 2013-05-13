//
//  MVFileUpload_Private.h
//  Chat
//
//  Created by Michaël Villar on 5/12/13.
//
//

#import "MVFileUpload.h"

@interface MVFileUpload ()

@property (strong, readwrite) NSString *key;
@property (strong, readwrite) NSData *data;
@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (readwrite) float uploadPercentage;
@property (readwrite, getter = isfinished) BOOL finished;
@property (readwrite, getter = isError) BOOL error;
@property (strong, readwrite) NSURL *remoteURL;
@property (strong, readwrite) NSURL *remoteURLForAsset;
@property (strong, readwrite) NSURLConnection *urlConnection;
@property (strong, readwrite) NSMutableData *mutableData;
@property (readwrite) NSInteger statusCode;

@end
