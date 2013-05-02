
#import "NSString+Digest.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Digest)

- (NSString*)mv_digest
{
  const char *cstr = [self cStringUsingEncoding:NSASCIIStringEncoding];
  NSData *data = [NSData dataWithBytes:cstr length:strlen(cstr)];
  uint8_t digest[CC_SHA1_DIGEST_LENGTH];

  CC_SHA1([data bytes], (int)[data length], digest);

  NSMutableString* outputHolder = [[NSMutableString alloc] initWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

  for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    [outputHolder appendFormat:@"%02x", digest[i]];
  }

  return [outputHolder copy];
}

@end
