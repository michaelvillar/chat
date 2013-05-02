
#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString*)mv_generateUUID
{
  CFUUIDRef UDIDRef = CFUUIDCreate(kCFAllocatorDefault);
  NSString *UDIDString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault,
                                                                          UDIDRef);
  CFRelease(UDIDRef);

  return UDIDString;
}

@end
