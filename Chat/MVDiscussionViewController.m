#import "MVDiscussionViewController.h"
#import "MVDiscussionView.h"
#import "MVDiscussionMessageItem.h"
#import "NSMutableAttributedString+LinksDetection.h"
#import "MVURLKit.h"

#define kMVChatConversationDateDisplayInterval 900

@interface MVDiscussionViewController ()

@property (strong, readwrite) NSMutableSet *addedObjectsSet;
@property (strong, readwrite) NSMutableSet *pendingServices;
@property (strong, readwrite) NSMutableSet *pendingMessageItems;
@property (strong, readwrite) NSDate *lastMessageDate;
@property (strong, readwrite) NSDate *firstMessageDate;
@property (strong, readwrite) NSDateFormatter *dayDateFormatter;
@property (strong, readwrite) MVDiscussionView *discussionView;
@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPJID *jid;

- (void)addDateMessageItemIfNeeded:(NSDate*)date
                          animated:(BOOL)animated
                            before:(BOOL)before;
- (NSArray*)messageItemsFromMessage:(XMPPMessage*)message;

@end

@implementation MVDiscussionViewController

@synthesize addedObjectsSet       = addedObjectsSet_,
            pendingServices       = pendingServices_,
            pendingMessageItems   = pendingMessageItems_,
            lastMessageDate       = lastMessageDate_,
            firstMessageDate      = firstMessageDate_,
            dayDateFormatter      = dayDateFormatter_,
            discussionView        = discussionView_,
            xmppStream            = xmppStream_,
            jid                   = jid_;

- (id)initWithDiscussionView:(MVDiscussionView*)discussionView
                  xmppStream:(XMPPStream*)xmppStream
                         jid:(XMPPJID*)jid
{
  self = [super init];
  if(self)
  {
    discussionView_ = discussionView;
    xmppStream_ = xmppStream;
    jid_ = jid;
    
    addedObjectsSet_ = [NSMutableSet set];
    pendingServices_ = [NSMutableSet set];
    pendingMessageItems_ = [NSMutableSet set];
    lastMessageDate_ = nil;
    firstMessageDate_ = nil;
    dayDateFormatter_ = [[NSDateFormatter alloc] init];
    [dayDateFormatter_ setDateFormat:@"yyyy-MM-dd"];
  }
  return self;
}

- (void)dealloc
{
  NSObject *service;
  for(service in self.pendingServices)
  {
    [service removeObserver:self forKeyPath:@"informationFetched"];
  }
}

- (void)reset
{
  self.lastMessageDate = nil;
  [self.addedObjectsSet removeAllObjects];
  [self.discussionView removeAllDiscussionItems];
}

- (void)addMessage:(XMPPMessage*)message
          animated:(BOOL)animated;
{
  NSArray *messageItems = [self messageItemsFromMessage:message];
  if(messageItems.count > 0)
  {
    MVDiscussionMessageItem *messageItem;
    [self addDateMessageItemIfNeeded:[NSDate date]
                            animated:animated
                              before:NO];
    
    for(messageItem in messageItems)
    {
      [self.discussionView addDiscussionItem:messageItem animated:animated];
    }

    [self.discussionView layoutSubviews:animated];
  }
}

- (void)addMessage:(XMPPMessage *)message animatedFromTextView:(MVRoundedTextView *)textView
{
  NSArray *messageItems = [self messageItemsFromMessage:message];
  if(messageItems.count == 0)
    return;
  [self.discussionView scrollToBottomAnimated:NO];
  [self addDateMessageItemIfNeeded:[NSDate date]
                          animated:YES
                            before:NO];
  MVDiscussionMessageItem *messageItem;
  for(messageItem in messageItems)
  {
    if(textView)
      [self.discussionView addDiscussionItem:messageItem
                         animateFromTextView:textView];
    else
      [self.discussionView addDiscussionItem:messageItem
                                    animated:YES];
  }
  [self.discussionView layoutSubviews:YES];
}


#pragma mark -
#pragma mark Private Methods

- (void)addDateMessageItemIfNeeded:(NSDate*)date
                          animated:(BOOL)animated
                            before:(BOOL)before
{
  NSDate *prevDate = (before ? self.firstMessageDate : self.lastMessageDate);
  NSDate *dateToDisplay = nil;
  NSDate *oldDate = nil;
  if(!prevDate) 
  {
    if(before)
      self.firstMessageDate = date;
    else
      self.lastMessageDate = date;
    dateToDisplay = date;
  }
  else if((!before && [date timeIntervalSinceDate:prevDate] >= 
          kMVChatConversationDateDisplayInterval) ||
          (before && [prevDate timeIntervalSinceDate:date] >= 
           kMVChatConversationDateDisplayInterval)) 
  {
    oldDate = prevDate;
    if(before)
      self.firstMessageDate = date;
    else
      self.lastMessageDate = date;
    dateToDisplay = date;
  }
  
  if(!self.lastMessageDate && before)
    self.lastMessageDate = self.firstMessageDate;
  else if(!self.firstMessageDate && !before)
    self.firstMessageDate = self.lastMessageDate;
  
  if(dateToDisplay) 
  {
    MVDiscussionMessageItem* messageItem = [[MVDiscussionMessageItem alloc] init];
    if(!oldDate || 
       ![[self.dayDateFormatter stringFromDate:dateToDisplay] 
         isEqualToString:[self.dayDateFormatter stringFromDate:oldDate]])
    {
      messageItem.type = kMVDiscussionMessageTypeFullTimestamp;
    }
    else
      messageItem.type = kMVDiscussionMessageTypeTimestamp;
    messageItem.date = dateToDisplay;
    if(before)
      [self.discussionView insertDiscussionItemAtTop:messageItem];
    else
      [self.discussionView addDiscussionItem:messageItem animated:animated];
  }
}

- (NSArray*)messageItemsFromMessage:(XMPPMessage*)message
{
  XMPPvCardAvatarModule *module = (XMPPvCardAvatarModule*)[self.xmppStream moduleOfClass:
                                                         [XMPPvCardAvatarModule class]];
  
  
  NSMutableArray *items = [NSMutableArray array];
  MVDiscussionMessageItem* messageItem;
  NSString *messageStr = [[message elementForName:@"body"] stringValue];
  NSArray *parsedMessages = [[MVURLKit sharedInstance] parseMessageForURLs:messageStr
                                                             mentionRanges:[NSSet set]];
  MVMessage *parsedMessage;
  for(parsedMessage in parsedMessages)
  {
    messageItem = [[MVDiscussionMessageItem alloc] init];
    messageItem.name = message.from.full;
    messageItem.own = ![message.from isEqualToJID:self.jid options:XMPPJIDCompareBare];
    messageItem.senderRepresentedObject = message.from;

    if(module)
    {
      NSData *photoData = [module photoDataForJID:message.from];
      if(photoData)
      {
        messageItem.avatar = [TUIImage imageWithData:photoData];
      }
    }
    
    if(parsedMessage.service)
    {
      if([parsedMessage.service isKindOfClass:[MVKickoffFileService class]])
      {
        MVKickoffFileService *service = (MVKickoffFileService*)(parsedMessage.service);
        MVAsset *asset = [[MVURLKit sharedInstance] assetForRemoteURL:service.url
                                                          withMaxSize:kMVDiscussionMessageMaxSize
                                                          ignoresGIFs:YES];
        CFStringRef fileExtension = (__bridge CFStringRef)(asset.localURL.pathExtension);
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, 
                                                                    fileExtension, 
                                                                    NULL);
        if(UTTypeConformsTo(fileUTI, kUTTypeJPEG) ||
           UTTypeConformsTo(fileUTI, kUTTypeJPEG2000) ||
           UTTypeConformsTo(fileUTI, kUTTypeTIFF) ||
           UTTypeConformsTo(fileUTI, kUTTypePICT) ||
           UTTypeConformsTo(fileUTI, kUTTypeGIF) ||
           UTTypeConformsTo(fileUTI, kUTTypePNG) ||
           UTTypeConformsTo(fileUTI, kUTTypeAppleICNS) ||
           UTTypeConformsTo(fileUTI, kUTTypeBMP) ||
           UTTypeConformsTo(fileUTI, kUTTypeICO))
          messageItem.type = kMVDiscussionMessageTypeImage;
        else
        {
          messageItem.type = kMVDiscussionMessageTypeFile;
          messageItem.attributedMessage = [[NSAttributedString alloc] 
                                           initWithString:asset.localURL.lastPathComponent];
        }
        messageItem.asset = asset;
        [messageItem bind:@"url" toObject:messageItem withKeyPath:@"asset.originalAsset.localURL" options:0];
      }
      else if([parsedMessage.service isKindOfClass:[MVImageService class]])
      {
        MVImageService *service = (MVImageService*)(parsedMessage.service);
        MVAsset *asset = [[MVURLKit sharedInstance] assetForRemoteURL:service.url
                                                           withMaxSize:kMVDiscussionMessageMaxSize
                                                           ignoresGIFs:YES];
        CFStringRef fileExtension = (__bridge CFStringRef)(asset.localURL.pathExtension);
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                    fileExtension,
                                                                    NULL);
        if(UTTypeConformsTo(fileUTI, kUTTypeJPEG) ||
           UTTypeConformsTo(fileUTI, kUTTypeJPEG2000) ||
           UTTypeConformsTo(fileUTI, kUTTypeTIFF) ||
           UTTypeConformsTo(fileUTI, kUTTypePICT) ||
           UTTypeConformsTo(fileUTI, kUTTypeGIF) ||
           UTTypeConformsTo(fileUTI, kUTTypePNG) ||
           UTTypeConformsTo(fileUTI, kUTTypeAppleICNS) ||
           UTTypeConformsTo(fileUTI, kUTTypeBMP) ||
           UTTypeConformsTo(fileUTI, kUTTypeICO))
          messageItem.type = kMVDiscussionMessageTypeRemoteImage;
        else
        {
          messageItem.type = kMVDiscussionMessageTypeRemoteFile;
          messageItem.attributedMessage = [[NSAttributedString alloc]
                                           initWithString:asset.localURL.lastPathComponent];
        }
        messageItem.asset = asset;
        messageItem.service = service;
        [messageItem bind:@"url" toObject:messageItem withKeyPath:@"service.url" options:0];
      }
      else if([parsedMessage.service isKindOfClass:[MVYoutubeVideoService class]] ||
              [parsedMessage.service isKindOfClass:[MVVimeoVideoService class]] ||
              [parsedMessage.service isKindOfClass:[MVDribbbleShotService class]] ||
              [parsedMessage.service isKindOfClass:[MVFlickrPhotoService class]] ||
              [parsedMessage.service isKindOfClass:[MVCloudAppLinkService class]] ||
              [parsedMessage.service isKindOfClass:[MVDroplrLinkService class]] ||
              [parsedMessage.service isKindOfClass:[MVTwitterTweetService class]])
      {
        messageItem.service = parsedMessage.service;
        [messageItem bind:@"url" toObject:messageItem withKeyPath:@"service.url" options:0];
        if([parsedMessage.service isKindOfClass:[MVYoutubeVideoService class]] ||
           [parsedMessage.service isKindOfClass:[MVVimeoVideoService class]])
        {
          messageItem.type = kMVDiscussionMessageTypeRemoteVideo;
        }
        else if([parsedMessage.service isKindOfClass:[MVDribbbleShotService class]] ||
                [parsedMessage.service isKindOfClass:[MVFlickrPhotoService class]] ||
                [parsedMessage.service isKindOfClass:[MVCloudAppLinkService class]] ||
                [parsedMessage.service isKindOfClass:[MVDroplrLinkService class]])
        {
          messageItem.type = kMVDiscussionMessageTypeRemoteImage;
        }
        else if([parsedMessage.service isKindOfClass:[MVTwitterTweetService class]])
        {
          messageItem.type = kMVDiscussionMessageTypeTweet;
        }
        messageItem.attributedMessage = parsedMessage.attributedString;
        [self.pendingServices addObject:parsedMessage.service];
        [self.pendingMessageItems addObject:messageItem];
        [parsedMessage.service addObserver:self 
                                forKeyPath:@"informationFetched" 
                                   options:0 
                                   context:(__bridge void*)messageItem];
      }
    }
    else
    {
      messageItem.attributedMessage = parsedMessage.attributedString;
      messageItem.type = kMVDiscussionMessageTypeText;
    }
    [items addObject:messageItem];
  }
  return items;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([keyPath isEqualToString:@"informationFetched"])
  {
    NSObject <MVService> *service = object;
    [service removeObserver:self forKeyPath:@"informationFetched"];
    [self.pendingServices removeObject:service];
    MVDiscussionMessageItem *messageItem = (__bridge MVDiscussionMessageItem*)context;
    
    if(service.error)
    {
      messageItem.type = kMVDiscussionMessageTypeText;
      NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]
                                                   initWithString:service.url.description];
      [attributedText mv_detectLinks];
      messageItem.attributedMessage = attributedText;
      [messageItem resetCachedSize];
    }
    else if([service isKindOfClass:[MVYoutubeVideoService class]])
    {
      MVYoutubeVideoService *youtubeService = (MVYoutubeVideoService*)service;
      messageItem.asset = [[MVURLKit sharedInstance] assetForRemoteURL:youtubeService.thumbnailUrl
                                                           withMaxSize:kMVDiscussionMessageMaxSize];
    }
    else if([service isKindOfClass:[MVVimeoVideoService class]])
    {
      MVVimeoVideoService *vimeoService = (MVVimeoVideoService*)service;
      messageItem.asset = [[MVURLKit sharedInstance] assetForRemoteURL:vimeoService.thumbnailUrl
                                                           withMaxSize:kMVDiscussionMessageMaxSize];
    }
    else if([service isKindOfClass:[MVDribbbleShotService class]])
    {
      MVDribbbleShotService *dribbbleService = (MVDribbbleShotService*)service;
      messageItem.asset = [[MVURLKit sharedInstance] assetForRemoteURL:dribbbleService.imageUrl];
    }
    else if([service isKindOfClass:[MVFlickrPhotoService class]])
    {
      MVFlickrPhotoService *flickrService = (MVFlickrPhotoService*)service;
      messageItem.asset = [[MVURLKit sharedInstance] assetForRemoteURL:flickrService.imageUrl
                                                           withMaxSize:kMVDiscussionMessageMaxSize
                                                           ignoresGIFs:YES];
    }
    else if([service isKindOfClass:[MVCloudAppLinkService class]])
    {
      MVCloudAppLinkService *cloudAppService = (MVCloudAppLinkService*)service;
      MVAsset *asset = [[MVURLKit sharedInstance] assetForRemoteURL:cloudAppService.downloadUrl
                                                         withMaxSize:kMVDiscussionMessageMaxSize
                                                         ignoresGIFs:YES];
      if(!cloudAppService.isImage)
      {
        messageItem.type = kMVDiscussionMessageTypeRemoteFile;
        messageItem.attributedMessage = [[NSAttributedString alloc]
                                         initWithString:asset.localURL.lastPathComponent];
      }
      messageItem.asset = asset;
    }
    else if([service isKindOfClass:[MVDroplrLinkService class]])
    {
      MVDroplrLinkService *droplrService = (MVDroplrLinkService*)service;
      MVAsset *asset = [[MVURLKit sharedInstance] assetForRemoteURL:droplrService.downloadUrl
                                                         withMaxSize:kMVDiscussionMessageMaxSize
                                                         ignoresGIFs:YES];
      if(!droplrService.isImage)
      {
        messageItem.type = kMVDiscussionMessageTypeRemoteFile;
        messageItem.attributedMessage = [[NSAttributedString alloc]
                                         initWithString:asset.localURL.lastPathComponent];
      }
      messageItem.asset = asset;
    }
    else if([service isKindOfClass:[MVTwitterTweetService class]])
    {
      MVTwitterTweetService *twitterService = (MVTwitterTweetService*)service;
      messageItem.attributedMessage = twitterService.attributedText;
      messageItem.asset = [[MVURLKit sharedInstance] assetForRemoteURL:twitterService.userImageUrl];
    }
    
    // don't need this reference anymore (was passed through context value which is not retained)
    [self.pendingMessageItems removeObject:messageItem];
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
