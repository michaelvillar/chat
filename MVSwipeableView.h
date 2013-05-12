//
//  MVSwipeableView.h
//  Chat
//
//  Created by Michaël Villar on 5/8/13.
//
//

#import <TwUI/TUIKit.h>

@protocol MVSwipeableViewDelegate;

@interface MVSwipeableView : TUIView

@property (weak, readwrite) NSObject <MVSwipeableViewDelegate> *delegate;
@property (readwrite, nonatomic) float contentViewTopMargin;

- (void)insertSwipeableSubview:(TUIView *)view
                       atIndex:(NSUInteger)index;
- (void)addSwipeableSubview:(TUIView *)view;
- (void)removeSwipeableSubview:(TUIView *)view;
- (void)setSwipeableSubviewsOrder:(NSArray *)views;
- (void)swipeToView:(TUIView *)view;

@end


@protocol MVSwipeableViewDelegate

@optional
- (void)swipeableView:(MVSwipeableView*)swipeableView
       didSwipeToView:(TUIView *)view;

@end