#import "MVDiscussionMessageItem.h"
#import "NSMutableAttributedString+LinksDetection.h"
#import "TUIImage+ProportionalResize.h"
#import "TUIImage+LocalURLCaching.h"
#import "MVURLKit.h"

@interface MVDiscussionMessageItem ()

@property (readwrite) CGSize cachedSize;
@property (readwrite) float cacheConstrainedToWidth;

- (void)createImageFromAsset;

@end

@implementation MVDiscussionMessageItem

@synthesize avatar                    = avatar_,
            avatarAsset               = avatarAsset_,
            name                      = name_,
            date                      = date_,
            own                       = own_,
            type                      = type_,
            offset                    = offset_,
            size                      = size_,
            previousItem              = previousItem_,
            animated                  = animated_,
            animationStyle            = animationStyle_,
            animating                 = animating_,
            animatingFromPoint        = animatingFromPoint_,
            selected                  = selected_,
            error                     = error_,
            remoteId                  = remoteId_,
            representedObject         = representedObject_,
            senderRepresentedObject   = senderRepresentedObject_,
            attributedMessage         = attributedMessage_,
            image                     = image_,
            url                       = url_,
            icon                      = icon_,
            asset                     = asset_,
            service                   = service_,
            ownMention                = ownMention_,
            mentions                  = mentions_,
            attributedNotificationAction  = attributedNotificationAction_,
            notificationDescription   = notificationDescription_,
            notificationType          = notificationType_,
            notificationClickable     = notificationClickable_,
            cachedSize                = cachedSize_,
            cacheConstrainedToWidth   = cacheConstrainedToWidth_,
            delegate                  = delegate_;

- (id)init
{
  self = [super init];
  if(self)
  {
    avatar_ = [TUIImage imageNamed:@"placeholder_avatar.png" cache:YES];
    avatarAsset_ = nil;
    name_ = nil;
    date_ = nil;
    own_ = NO;
    type_ = kMVDiscussionMessageTypeText;
    offset_ = 0;
    size_ = CGSizeZero;
    previousItem_ = nil;
    animated_ = NO;
    animationStyle_ = kMVDiscussionMessageAnimationStyleNormal;
    animating_ = NO;
    animatingFromPoint_ = CGPointZero;
    selected_ = NO;
    error_ = NO;
    remoteId_ = -1;
    representedObject_ = nil;
    senderRepresentedObject_ = nil;
    attributedMessage_ = nil;
    image_ = nil;
    url_ = nil;
    icon_ = nil;
    asset_ = nil;
    service_ = nil;
    ownMention_ = NO;
    mentions_ = [NSSet set];
    attributedNotificationAction_ = nil;
    notificationDescription_ = nil;
    notificationType_ = kMVDiscussionNotificationTypeTaskNew;
    notificationClickable_ = NO;
    cachedSize_ = CGSizeZero;
    cacheConstrainedToWidth_ = 0;
    delegate_ = nil;

    [self addObserver:self forKeyPath:@"asset" options:0 context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [self unbind:@"url"];
  [self removeObserver:self forKeyPath:@"asset"];
  if(asset_)
  {
    [asset_ removeObserver:self forKeyPath:@"error"];
    [asset_ removeObserver:self forKeyPath:@"existing"];
    [asset_ removeObserver:self forKeyPath:@"uploadFinished"];
  }
  if(avatarAsset_)
    [avatarAsset_ removeObserver:self forKeyPath:@"existing"];
}

- (void)setAvatarAsset:(MVAsset *)avatarAsset
{
  if(avatarAsset == avatarAsset_)
    return;
  if(avatarAsset_)
    [avatarAsset_ removeObserver:self forKeyPath:@"existing"];
  [avatarAsset addObserver:self forKeyPath:@"existing" options:0 context:NULL];
  avatarAsset_ = avatarAsset;
  if(avatarAsset.isExisting)
  {
    self.avatar = [TUIImage imageWithContentsOfURL:self.avatarAsset.localURL cache:YES];
  }
  else
  {
    self.avatar = [TUIImage imageNamed:@"placeholder_avatar.png" cache:YES];
  }
}

- (void)setAsset:(MVAsset *)asset
{
  if(asset == asset_)
    return;
  if(asset_)
  {
    [asset_ removeObserver:self forKeyPath:@"error"];
    [asset_ removeObserver:self forKeyPath:@"existing"];
    [asset_ removeObserver:self forKeyPath:@"uploadFinished"];
  }
  asset_ = asset;
  self.image = nil;
  if(asset_)
  {
    [asset_ addObserver:self forKeyPath:@"error" options:0 context:NULL];
    [asset_ addObserver:self forKeyPath:@"existing" options:0 context:NULL];
    [asset_ addObserver:self forKeyPath:@"uploadFinished" options:0 context:NULL];
  }
  self.error = asset_.error;
}

- (NSString*)message
{
  return self.attributedMessage.string;
}

- (void)setAttributedMessage:(NSAttributedString *)attributedMessage
{
  if(attributedMessage == attributedMessage_)
    return;
  NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
                                                initWithAttributedString:attributedMessage];
  [string setFont:[TUIFont systemFontOfSize:12]];
  if(self.type == kMVDiscussionMessageTypeFile ||
     self.type == kMVDiscussionMessageTypeRemoteFile)
  {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [string addAttribute:NSParagraphStyleAttributeName
                            value:style
                            range:NSMakeRange(0, string.length)];
  }
  [attributedMessage enumerateAttribute:kMVMentionAttributeName
                                inRange:NSMakeRange(0, attributedMessage.length)
                                options:0
                             usingBlock:^(id value, NSRange range, BOOL *stop)
  {
    if(value && [value isKindOfClass:[NSString class]] && [value isEqualToString:@"YES"])
      [string setFont:[TUIFont boldSystemFontOfSize:12] inRange:range];
  }];
  if(string.length > kMVMessageMaxChars)
    [string replaceCharactersInRange:NSMakeRange(kMVMessageMaxChars,
                                                 string.length - kMVMessageMaxChars)
                          withString:@""];

  attributedMessage_ = string;
}

- (void)setImage:(TUIImage *)image
{
  if(image == image_)
    return;
  image_ = image;
}

- (void)resetCachedSize
{
  if(self.cacheConstrainedToWidth == 0)
    return;
  self.cacheConstrainedToWidth = 0;
  if([self.delegate respondsToSelector:@selector(discussionMessageItemDidClearCachedSize:)])
    [self.delegate discussionMessageItemDidClearCachedSize:self];
}

- (void)openURL
{
  NSURL *url = self.url;
  if([self.service isKindOfClass:[MVCloudAppLinkService class]] ||
     [self.service isKindOfClass:[MVDroplrLinkService class]] ||
     [self.service isKindOfClass:[MVFlickrPhotoService class]] ||
     [self.service isKindOfClass:[MVDribbbleShotService class]] ||
     [self.service isKindOfClass:[MVImageService class]])
    url = self.asset.originalAsset.localURL;
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (NSImage*)icon
{
  if(!icon_)
  {
    icon_ = [[NSWorkspace sharedWorkspace] iconForFile:self.asset.localURL.path];
  }
  return icon_;
}

- (BOOL)sameSenderAsPreviousItem
{
  if(!self.previousItem)
    return NO;
  MVDiscussionMessageItem *item = self.previousItem;
  while(item.type == kMVDiscussionMessageTypeWriting &&
        [item.senderRepresentedObject isEqual:self.senderRepresentedObject])
  {
    item = item.previousItem;
    if(!item)
      return NO;
  }
  return [item.senderRepresentedObject isEqual:self.senderRepresentedObject]
        && item.type != kMVDiscussionMessageTypeNotification;
}

- (void)setPreviousItem:(MVDiscussionMessageItem *)previousItem
{
  if(previousItem_ == previousItem)
    return;
  BOOL sameSender = self.sameSenderAsPreviousItem;
  previousItem_ = previousItem;
  if(sameSender != self.sameSenderAsPreviousItem)
  {
    [self willChangeValueForKey:@"sameSenderAsPreviousItem"];
    [self didChangeValueForKey:@"sameSenderAsPreviousItem"];
  }
}

- (NSString*)notificationAction
{
  if(self.attributedNotificationAction)
    return self.attributedNotificationAction.string;
  return nil;
}

- (BOOL)isFailedSentMessage
{
  return self.own && self.remoteId == 0;
}

- (NSString*)formattedMessageSubstringWithRange:(NSRange)range
{
  __block int offset = 0;
  NSAttributedString *attributedString = [self.attributedMessage attributedSubstringFromRange:range];
  NSMutableString *formattedMessage = [NSMutableString stringWithString:attributedString.string];
  [attributedString enumerateAttribute:NSLinkAttributeName
                               inRange:NSMakeRange(0, attributedString.length)
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop)
  {
    if(value && [value isKindOfClass:[NSURL class]])
    {
      NSURL *url = (NSURL*)value;
      NSString *urlString = url.absoluteString;
      NSRange replacedRange = NSMakeRange(range.location + offset, range.length);
      [formattedMessage replaceCharactersInRange:replacedRange
                                      withString:urlString];
      offset += urlString.length - replacedRange.length;
    }
  }];
  return formattedMessage;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if(object == self)
  {
    if([keyPath isEqualToString:@"asset"])
    {
      if(self.asset.isExisting)
      {
        if(self.type == kMVDiscussionMessageTypeImage ||
           self.type == kMVDiscussionMessageTypeRemoteVideo ||
           self.type == kMVDiscussionMessageTypeRemoteImage ||
           self.type == kMVDiscussionMessageTypeTweet)
          [self createImageFromAsset];
        if(self.type == kMVDiscussionMessageTypeRemoteFile)
          [self resetCachedSize];
      }
    }
  }
  else if(object == self.asset)
  {
    if([keyPath isEqualToString:@"existing"] &&
       self.asset.isExisting &&
       self.image == nil &&
       (self.type == kMVDiscussionMessageTypeImage ||
        self.type == kMVDiscussionMessageTypeRemoteVideo ||
        self.type == kMVDiscussionMessageTypeRemoteImage ||
        self.type == kMVDiscussionMessageTypeTweet))
    {
      [self createImageFromAsset];
    }
    if(([keyPath isEqualToString:@"uploadFinished"] &&
        self.asset.uploadFinished &&
        (self.type == kMVDiscussionMessageTypeFile ||
         self.type == kMVDiscussionMessageTypeRemoteFile)) ||
       ([keyPath isEqualToString:@"existing"] &&
        self.asset.isExisting &&
        (self.type == kMVDiscussionMessageTypeFile ||
         self.type == kMVDiscussionMessageTypeRemoteFile)))
    {
      icon_ = nil;
      [self resetCachedSize];
    }
    if([keyPath isEqualToString:@"error"])
    {
      if(self.type == kMVDiscussionMessageTypeRemoteImage ||
         self.type == kMVDiscussionMessageTypeRemoteFile ||
         self.type == kMVDiscussionMessageTypeRemoteVideo ||
         self.type == kMVDiscussionMessageTypeTweet)
      {
        self.type = kMVDiscussionMessageTypeText;
        [self resetCachedSize];
      }
      else
      {
        self.error = self.asset.error;
      }
    }
  }
  else if(object == self.avatarAsset)
  {
    if(self.avatarAsset.isExisting)
    {
      self.avatar = [TUIImage imageWithContentsOfURL:self.avatarAsset.localURL cache:YES];
    }
    else
    {
      self.avatar = [TUIImage imageNamed:@"placeholder_avatar.png" cache:YES];
    }
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark QLPreviewItem Methods

- (NSURL *)previewItemURL
{
  if(self.type == kMVDiscussionMessageTypeRemoteImage ||
     self.type == kMVDiscussionMessageTypeRemoteFile)
    return self.asset.originalAsset.localURL;
  return self.url;
}

- (NSString *)previewItemTitle
{
  if(self.type == kMVDiscussionMessageTypeRemoteImage ||
     self.type == kMVDiscussionMessageTypeRemoteFile)
    return self.asset.originalAsset.localURL.lastPathComponent;
  return self.url.lastPathComponent;
}

#pragma mark -
#pragma mark Private Methods

- (void)createImageFromAsset
{
  NSData *data = [NSData dataWithContentsOfURL:self.asset.localURL];
  NSImage *nsImage = [[NSImage alloc] initWithData:data];
  if([self.asset.localURL.pathExtension.lowercaseString isEqualToString:@"gif"])
    self.image = [TUIImage animatedImageWithData:data];
  else
    self.image = [TUIImage imageWithNSImage:nsImage];
  [self resetCachedSize];
}

@end
