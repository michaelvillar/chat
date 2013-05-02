#import "MVAsset.h"

@class MVFileDownload,
       MVFileUpload;

@interface MVAsset ()

@property (strong, readwrite, nonatomic) MVFileDownload *fileDownload;
@property (strong, readwrite, nonatomic) MVFileUpload *fileUpload;

- (void)generateResizedFile;

@end
