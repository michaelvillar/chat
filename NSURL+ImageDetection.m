#import "NSURL+ImageDetection.h"

@implementation NSURL (ImageDetection)

- (BOOL)mv_isImage
{
  CFStringRef fileExtension = (__bridge CFStringRef)(self.pathExtension);
  CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                              fileExtension,
                                                              NULL);
  return (UTTypeConformsTo(fileUTI, kUTTypeJPEG) ||
          UTTypeConformsTo(fileUTI, kUTTypeJPEG2000) ||
          UTTypeConformsTo(fileUTI, kUTTypeTIFF) ||
          UTTypeConformsTo(fileUTI, kUTTypePICT) ||
          UTTypeConformsTo(fileUTI, kUTTypeGIF) ||
          UTTypeConformsTo(fileUTI, kUTTypePNG) ||
          UTTypeConformsTo(fileUTI, kUTTypeAppleICNS) ||
          UTTypeConformsTo(fileUTI, kUTTypeBMP) ||
          UTTypeConformsTo(fileUTI, kUTTypeICO));
}

@end
