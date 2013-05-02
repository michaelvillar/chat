#import <TwUI/TUIKit.h>

#define kMVCircleLoaderStyleWhite 1
#define kMVCircleLoaderStyleEmbossedBlue 2
#define kMVCircleLoaderStyleEmbossedGrey 3

@interface MVCircleLoaderView : TUIView

@property (readwrite, nonatomic) float percentage;
@property (readwrite) int style;

@end
