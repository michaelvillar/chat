@interface NSPasteboard (EnumerateKeysAndDatas)

- (BOOL)mv_hasDetectedFile;
- (void)mv_enumerateKeysAndDatas:(void (^)(NSString *key, NSData *data))block;

@end
