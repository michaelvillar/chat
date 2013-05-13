//
//  MVCloudAppFileUpload.m
//  Chat
//
//  Created by Michaël Villar on 5/12/13.
//
//

#import "MVCloudAppFileUpload.h"
#import "MVUploadAuthorization.h"
#import "Cloud.h"
#import "MVFileUpload_Private.h"

@interface MVCloudAppFileUpload () <CLAPIEngineDelegate>

@property (strong, readonly, nonatomic) CLAPIEngine *clApiEngine;

@end

@implementation MVCloudAppFileUpload

@synthesize clApiEngine = clApiEngine_;

- (void)start
{
  [self.clApiEngine uploadFileWithName:self.key
                              fileData:self.data
                              userInfo:@""];
}

#pragma mark CLAPIEngineDelegate Methods

- (void)requestDidFailWithError:(NSError *)error
           connectionIdentifier:(NSString *)connectionIdentifier
                       userInfo:(id)userInfo
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
      [self.delegate fileUpload:self didFailWithError:error];
    self.error = YES;
  });
}

- (void)fileUploadDidProgress:(CGFloat)percentageComplete
         connectionIdentifier:(NSString *)connectionIdentifier
                     userInfo:(id)userInfo
{
  self.uploadPercentage = percentageComplete * 100;
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileUpload:didProgress:)])
      [self.delegate fileUpload:self didProgress:percentageComplete * 100];
  });
}

- (void)fileUploadDidSucceedWithResultingItem:(CLWebItem *)item
                         connectionIdentifier:(NSString *)connectionIdentifier
                                     userInfo:(id)userInfo
{
  self.remoteURL = item.URL;
  self.remoteURLForAsset = [[item.URL URLByAppendingPathComponent:@"download"]
                            URLByAppendingPathComponent:item.name];
  
  if(self.uploadPercentage != 100)
  {
    self.uploadPercentage = 100;
  }
  
  self.finished = YES;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileUploadDidFinish:)])
      [self.delegate fileUploadDidFinish:self];
  });
}

#pragma mark Private Properties 

- (CLAPIEngine*)clApiEngine
{
  if(!clApiEngine_)
  {
    clApiEngine_ = [CLAPIEngine engineWithDelegate:self];
    clApiEngine_.clearsCookies = YES;
    clApiEngine_.email = self.uploadAuthorization.email;
    clApiEngine_.password = self.uploadAuthorization.password;
  }
  return clApiEngine_;
}

@end
