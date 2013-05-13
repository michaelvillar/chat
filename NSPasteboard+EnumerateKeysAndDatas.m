#import "NSPasteboard+EnumerateKeysAndDatas.h"

@implementation NSPasteboard (EnumerateKeysAndDatas)

- (BOOL)mv_hasDetectedFile
{
  NSString *type = [self availableTypeFromArray:
                    [NSArray arrayWithObjects:
                     NSFilenamesPboardType,
                     NSTIFFPboardType,
                     NSPasteboardTypeTIFF,
                     NSPasteboardTypePNG,
                     nil]];
  return (type != nil);
}

- (void)mv_enumerateKeysAndDatas:(void (^)(NSString *key, NSData *data))block
{
  NSMutableArray *keysAndDatas = [NSMutableArray array];
  NSString *type = [self availableTypeFromArray:
                    [NSArray arrayWithObjects:
                     NSFilenamesPboardType,
                     NSPasteboardTypePNG,
                     NSTIFFPboardType,
                     NSPasteboardTypeTIFF,
                     nil]];
  if(type)
  {
    NSData *data = [self dataForType:type];
    if(type == NSTIFFPboardType || type == NSPasteboardTypeTIFF || type == NSPasteboardTypePNG) 
    {
      NSArray *extensions = [self propertyListForType:NSFilesPromisePboardType];
      NSString *extension = @"png";
      if(extensions.count > 0)
        extension = [[extensions objectAtIndex:0] lowercaseString];
      
      NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
      NSString *key = [NSString stringWithFormat:@"image-%@.%@",
                       [formatter stringFromDate:[NSDate date]], extension];
      
      NSUInteger fileType = NSPNGFileType;
      if([extension isEqual:@"jpeg"] || [extension isEqual:@"jpg"])
        fileType = NSJPEGFileType;
      else if([extension isEqual:@"gif"])
        fileType = NSGIFFileType;
      else if([extension isEqual:@"bmp"])
        fileType = NSBMPFileType;
      else if([extension isEqual:@"tiff"])
        fileType = NSTIFFFileType;
      data = [[NSBitmapImageRep imageRepWithData:data] representationUsingType:fileType 
                                                                    properties:nil];
      [keysAndDatas addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               key, @"key",
                               data, @"data",
                               nil]];
    }
    else if(type == NSFilenamesPboardType)
    {
      NSString* errorDescription;
      NSArray *originalFiles = [NSPropertyListSerialization propertyListFromData:data
                                                                mutabilityOption:kCFPropertyListImmutable
                                                                          format:nil
                                                                errorDescription:&errorDescription];
      
      NSString *file;
      for(file in originalFiles) 
      {
        BOOL isDirectory;
        if([[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory]) 
        {
          if(!isDirectory)
          {
            // upload files in sequential (to keep order)
            NSData *data = [NSData dataWithContentsOfFile:file];
            NSString *key = [file lastPathComponent];
            [keysAndDatas addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     key, @"key",
                                     data, @"data",
                                     nil]];
          }
        }
      }
    }
  }
  
  NSDictionary *dic;
  for(dic in keysAndDatas)
  {
    block([dic valueForKey:@"key"], [dic valueForKey:@"data"]);
  }
}

@end
