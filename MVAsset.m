#import "MVAsset.h"
#import "MVAsset_Private.h"
#import "MVFileDownload.h"
#import "MVFileUpload.h"
#import "MVAssetsManager_Private.h"

@interface MVAsset ()

@property (strong, readwrite) MVAssetsManager *assetsManager;
@property (readwrite) CGSize maxSize;

@end

@implementation MVAsset

@synthesize remoteURL         = remoteURL_,
            fileDownload      = fileDownload_,
            fileUpload        = fileUpload_,
            assetsManager     = assetsManager_,
            maxSize           = maxSize_,
            originalAsset     = originalAsset_;

- (id)initWithRemoteURL:(NSURL*)remoteURL
          assetsManager:(MVAssetsManager*)assetsManager
{
  return [self initWithRemoteURL:remoteURL assetsManager:assetsManager withMaxSize:CGSizeZero];
}

- (id)initWithRemoteURL:(NSURL*)remoteURL
          assetsManager:(MVAssetsManager*)assetsManager
            withMaxSize:(CGSize)maxSize
{
  self = [super init];
  if(self)
  {
    remoteURL_ = remoteURL;
    fileDownload_ = nil;
    fileUpload_ = nil;
    assetsManager_ = assetsManager;
    maxSize_ = maxSize;
    originalAsset_ = nil;
  }
  return self;
}

- (void)retryDownload
{
  if(!self.error || !self.fileDownload || self.isExisting)
    return;
  MVFileDownload *fileDownload = self.fileDownload;
  MVFileDownload *newFileDownload = [[MVFileDownload alloc]
                                     initWithSourceURL:fileDownload.sourceURL
                                        destinationURL:fileDownload.destinationURL
                                        operationQueue:fileDownload.operationQueue];
  [self willChangeValueForKey:@"error"];
  self.fileDownload = newFileDownload;
  [newFileDownload start];
  [self didChangeValueForKey:@"error"];
}

- (void)retryUpload
{
  [self.assetsManager retryUpload:self];
}

- (void)dealloc
{
  if(fileDownload_)
  {
    [fileDownload_ removeObserver:self forKeyPath:@"downloadPercentage"];
    [fileDownload_ removeObserver:self forKeyPath:@"finished"];
    [fileDownload_ removeObserver:self forKeyPath:@"error"];
  }
  if(fileUpload_)
  {
    [fileUpload_ removeObserver:self forKeyPath:@"uploadPercentage"];
    [fileUpload_ removeObserver:self forKeyPath:@"finished"];
    [fileUpload_ removeObserver:self forKeyPath:@"error"];
  }
}

- (BOOL)isExisting
{
  return [[NSFileManager defaultManager] fileExistsAtPath:[self.localURL path]];
}

- (float)downloadPercentage
{
  if(self.fileDownload)
    return self.fileDownload.downloadPercentage;
  return (self.isExisting ? 100 : 0);
}

- (float)uploadPercentage
{
  if(self.fileUpload)
    return self.fileUpload.uploadPercentage;
  return 100;
}

- (BOOL)uploadFinished
{
  if(self.fileUpload)
    return self.fileUpload.finished;
  return YES;
}

- (NSURL*)localURL
{
  if(self.maxSize.width == 0 || self.maxSize.height == 0)
    return [self.assetsManager resolveLocalURLForRemoteURL:self.remoteURL];
  return [self.assetsManager resolveLocalURLForRemoteURL:self.remoteURL
                                                andToken:[NSString stringWithFormat:
                                                          @"size=%f,%f",
                                                          self.maxSize.width, self.maxSize.height]];
}

- (BOOL)error
{
  return (self.fileDownload ? self.fileDownload.error : NO) ||
         (self.fileUpload ? self.fileUpload.error : NO);
}

- (MVAsset*)originalAsset
{
  if(originalAsset_)
    return originalAsset_;
  return self;
}

- (NSURL*)fileUploadRemoteURL
{
  if(self.fileUpload)
    return self.fileUpload.remoteURL;
  return nil;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  __strong __block MVAsset *myAsset = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    if([keyPath isEqualToString:@"downloadPercentage"])
    {
      [myAsset willChangeValueForKey:@"downloadPercentage"];
      [myAsset didChangeValueForKey:@"downloadPercentage"];
    }
    else if([keyPath isEqualToString:@"uploadPercentage"])
    {
      [myAsset willChangeValueForKey:@"uploadPercentage"];
      [myAsset didChangeValueForKey:@"uploadPercentage"];
    }
    else if([keyPath isEqualToString:@"finished"])
    {
      if(object == myAsset.fileUpload)
      {
        NSURL *currentLocalURL = myAsset.localURL;

        [myAsset willChangeValueForKey:@"localURL"];
        myAsset.remoteURL = myAsset.fileUpload.remoteURLForAsset;
        [myAsset didChangeValueForKey:@"localURL"];

        if(![currentLocalURL isEqual:self.localURL])
        {
          NSFileManager *fileManager = [NSFileManager defaultManager];
          [fileManager createDirectoryAtPath:myAsset.localURL.path.stringByDeletingLastPathComponent
                 withIntermediateDirectories:YES
                                  attributes:nil
                                       error:nil];
          [fileManager moveItemAtURL:currentLocalURL toURL:myAsset.localURL error:nil];
        }

        [myAsset willChangeValueForKey:@"uploadFinished"];
        [myAsset didChangeValueForKey:@"uploadFinished"];
      }
      else
      {
        [myAsset willChangeValueForKey:@"existing"];
        [myAsset didChangeValueForKey:@"existing"];
        [self generateResizedFile];
      }
    }
    else if([keyPath isEqualToString:@"error"] &&
            (object == myAsset.fileDownload || object == myAsset.fileUpload))
    {
      [myAsset willChangeValueForKey:@"error"];
      [myAsset didChangeValueForKey:@"error"];
    }
    else
      [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    myAsset = nil;
  });
}

#pragma mark -
#pragma mark Private Methods

- (void)generateResizedFile
{
  if(self.isExisting || self.maxSize.width == 0 || self.maxSize.height == 0)
    return;

  NSURL *sourceURL = self.originalAsset.localURL;
  NSURL *destinationURL = self.localURL;

  NSData *data = [NSData dataWithContentsOfURL:sourceURL];
  CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	if(!imageSource)
  {
    NSLog(@"ImageSource doesn't exists!");
		return;
	}

	CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
	if(!image)
  {
		NSLog(@"Image doesn't exists!");
    return;
	}

  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);

  CGSize currentSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
  CGSize size = CGSizeZero;
  CGSize maxSize = self.maxSize;
  float currentRatio = currentSize.width / currentSize.height;
  if(maxSize.width / currentSize.width > 1 && maxSize.height / currentSize.height > 1)
  {
    size = currentSize;
  }
  else if(maxSize.width / currentSize.width < maxSize.height / currentSize.height)
  {
    size.width = maxSize.width;
    size.height = size.width / currentRatio;
  }
  else
  {
    size.height = maxSize.height;
    size.width = size.height * currentRatio;
  }

  size_t width = size.width;
	size_t height = size.height;
	size_t bitsPerComponent = 8;
	size_t bytesPerRow = 4 * width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, bitsPerComponent,
                                           bytesPerRow, colorSpace, bitmapInfo);
	CGColorSpaceRelease(colorSpace);

  CGRect r;
  r.origin = CGPointZero;
  r.size = size;
  CGContextDrawImage(ctx, r, image);

  CGImageRelease(image);
  CFRelease(imageSource);

  image = CGBitmapContextCreateImage(ctx);

  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager createDirectoryAtPath:destinationURL.path.stringByDeletingLastPathComponent
         withIntermediateDirectories:YES
                          attributes:nil
                               error:nil];

  CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                              (__bridge CFStringRef)
                                                              (destinationURL.path.pathExtension),
                                                              NULL);

  CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)destinationURL,
                                                                      fileUTI,
                                                                      1, NULL);
  CGImageDestinationAddImage(destination, image, properties);
  if (!CGImageDestinationFinalize(destination))
  {
    NSLog(@"Failed to write image to %@", destinationURL);
  }

  CGImageRelease(image);
  CGContextRelease(ctx);

  [self willChangeValueForKey:@"existing"];
  [self didChangeValueForKey:@"existing"];
}

#pragma mark -
#pragma mark Private Properties

- (void)setFileDownload:(MVFileDownload *)fileDownload
{
  if(fileDownload == fileDownload_)
    return;
  [fileDownload_ removeObserver:self forKeyPath:@"downloadPercentage"];
  [fileDownload_ removeObserver:self forKeyPath:@"finished"];
  [fileDownload_ removeObserver:self forKeyPath:@"error"];
  fileDownload_ = fileDownload;
  if(fileDownload)
  {
    [fileDownload addObserver:self
                   forKeyPath:@"downloadPercentage"
                      options:0
                      context:NULL];
    [fileDownload addObserver:self
                   forKeyPath:@"finished"
                      options:0
                      context:NULL];
    [fileDownload addObserver:self
                   forKeyPath:@"error"
                      options:0
                      context:NULL];
  }
}

- (void)setFileUpload:(MVFileUpload *)fileUpload
{
  if(fileUpload == fileUpload_)
    return;
  [fileUpload_ removeObserver:self forKeyPath:@"uploadPercentage"];
  [fileUpload_ removeObserver:self forKeyPath:@"finished"];
  [fileUpload_ removeObserver:self forKeyPath:@"error"];
  [self willChangeValueForKey:@"error"];
  [self willChangeValueForKey:@"uploadFinished"];
  [self willChangeValueForKey:@"uploadPercentage"];
  fileUpload_ = fileUpload;
  [self didChangeValueForKey:@"uploadPercentage"];
  [self didChangeValueForKey:@"uploadFinished"];
  [self didChangeValueForKey:@"error"];
  if(fileUpload)
  {
    [fileUpload addObserver:self
                 forKeyPath:@"uploadPercentage"
                    options:0
                    context:NULL];
    [fileUpload addObserver:self
                 forKeyPath:@"finished"
                    options:0
                    context:NULL];
    [fileUpload addObserver:self
                 forKeyPath:@"error"
                    options:0
                    context:NULL];
  }
}

@end
