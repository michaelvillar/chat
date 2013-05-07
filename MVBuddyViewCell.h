//
//  MVBuddyViewCell.h
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import <TwUI/TUIKit.h>

@interface MVBuddyViewCell : TUITableViewCell

@property (copy) NSString *fullname;
@property (copy) NSString *email;
@property (readwrite, getter = isOnline) BOOL online;
@property (readwrite, strong) TUIImage *avatar;
@property (readwrite, getter = isAlternate) BOOL alternate;
@property (readwrite, getter = isFirstRow) BOOL firstRow;
@property (readwrite, getter = isLastRow) BOOL lastRow;

@end
