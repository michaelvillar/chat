#import <Foundation/Foundation.h>
#import <TwUI/TUIKit.h>
#import <Quartz/Quartz.h>

@protocol MVService;
@class MVAsset,
       MVDiscussionMessageItem;

#define kMVDiscussionMessageTypeText 1
#define kMVDiscussionMessageTypeImage 2
#define kMVDiscussionMessageTypeFile 3
#define kMVDiscussionMessageTypeTimestamp 4
#define kMVDiscussionMessageTypeFullTimestamp 5
#define kMVDiscussionMessageTypeNotification 6
#define kMVDiscussionMessageTypeRemoteVideo 7
#define kMVDiscussionMessageTypeRemoteImage 8
#define kMVDiscussionMessageTypeRemoteFile 9
#define kMVDiscussionMessageTypeTweet 10
#define kMVDiscussionMessageTypeWriting 111

#define kMVDiscussionMessageAnimationStyleNormal 1
#define kMVDiscussionMessageAnimationStyleSentMessage 2

#define kMVDiscussionNotificationTypeOnlinePresence 2
#define kMVDiscussionNotificationTypeOfflinePresence 3
#define kMVDiscussionNotificationTypeTeamJoined 4
#define kMVDiscussionNotificationTypeTeamLeft 5
#define kMVDiscussionNotificationTypeTaskChecked 6
#define kMVDiscussionNotificationTypeTaskNew 7
#define kMVDiscussionNotificationTypeComment 8

#define kMVDiscussionMessageMaxSize CGSizeMake(500,500)

@protocol MVDiscussionMessageItemDelegate
@optional
- (void)discussionMessageItemDidClearCachedSize:(MVDiscussionMessageItem*)item;
- (void)discussionMessageItemShouldRetryFileTransfer:(MVDiscussionMessageItem*)item;
- (void)discussionMessageItemShouldRetrySendingMessage:(MVDiscussionMessageItem *)item;
@end

@interface MVDiscussionMessageItem : NSObject <QLPreviewItem>

@property (strong, readwrite) TUIImage *avatar;
@property (strong, readwrite, nonatomic) MVAsset *avatarAsset;
@property (strong, readwrite) NSString *name;
@property (strong, readwrite) NSDate *date;
@property (readwrite) BOOL own;
@property (readwrite) int type;
@property (readwrite) float offset;
@property (readwrite) CGSize size;
@property (readonly) BOOL sameSenderAsPreviousItem;
@property (strong, readwrite, nonatomic) MVDiscussionMessageItem *previousItem;
@property (readwrite, getter = isAnimated) BOOL animated;
@property (readwrite) int animationStyle;
@property (readwrite, getter = isAnimating) BOOL animating;
@property (readwrite) CGPoint animatingFromPoint;
@property (readwrite, getter = isSelected) BOOL selected;
@property (readwrite, getter = isError) BOOL error;
@property (readwrite, getter = isFailedSentMessage, nonatomic) BOOL failedSentMessage;
@property (readwrite) int remoteId;
@property (strong, readwrite) NSObject *representedObject;
@property (strong, readwrite) NSObject *senderRepresentedObject;
@property (strong, readwrite, nonatomic) MVAsset *asset;
@property (strong, readwrite, nonatomic) NSObject<MVService> *service;

// Mentions
@property (readwrite) BOOL ownMention;
@property (strong, readwrite) NSSet *mentions; // set of NSValue range objects

// Text type
@property (strong, readonly, nonatomic) NSString *message;
@property (strong, readwrite, nonatomic) NSAttributedString *attributedMessage;

// Image/RemoteVideo type
@property (strong, readwrite, nonatomic) TUIImage *image;

// File/Image type
@property (strong, readwrite) NSURL *url;
@property (strong, readonly, nonatomic) NSImage *icon;

// Notification type
@property (strong, readonly, nonatomic) NSString *notificationAction;
@property (strong, readwrite) NSAttributedString *attributedNotificationAction;
@property (strong, readwrite) NSString *notificationDescription;
@property (readwrite) int notificationType;
@property (readwrite) BOOL notificationClickable;

// Delegate
@property (weak, readwrite) NSObject <MVDiscussionMessageItemDelegate> *delegate;

- (void)resetCachedSize;
- (void)openURL;
- (NSString*)formattedMessageSubstringWithRange:(NSRange)range;

@end
