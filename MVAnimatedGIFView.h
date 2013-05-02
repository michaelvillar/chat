#import <TwUI/TUIKit.h>

@interface MVAnimatedGIFView : TUIView

- (id)initWithFrame:(CGRect)frame
              image:(TUIImage*)image
    preDrawingBlock:(TUIViewDrawRect)preDrawingBlock
   postDrawingBlock:(TUIViewDrawRect)postDrawingBlock;
- (void)startAnimating;
- (void)stopAnimating;

@end
