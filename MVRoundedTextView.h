#import <TwUI/TUIKit.h>

@class MVRoundedTextView;

@protocol MVRoundedTextViewCompletionSource
- (NSArray*)roundedTextView:(MVRoundedTextView*)textView
    completionsForSubstring:(NSString*)substring;
@end

@protocol MVRoundedTextViewDelegate
@optional
- (void)roundedTextViewDidResize:(MVRoundedTextView*)roundedTextView
                        animated:(BOOL)animated;
- (BOOL)roundedTextView:(MVRoundedTextView*)roundedTextView
             sendString:(NSString*)string;
- (void)roundedTextViewCancelOperation:(MVRoundedTextView*)roundedTextView;
- (void)roundedTextViewMoveUp:(MVRoundedTextView*)roundedTextView;
- (void)roundedTextViewTextDidChange:(MVRoundedTextView*)textView;
- (BOOL)roundedTextView:(MVRoundedTextView*)roundedTextView
        pastePasteboard:(NSPasteboard*)pasteboard;
- (BOOL)roundedTextView:(MVRoundedTextView*)roundedTextView
      didDropPasteboard:(NSPasteboard*)pasteboard;
- (void)roundedTextViewDidBecomeFirstResponder:(MVRoundedTextView*)roundedTextView;
- (void)roundedTextViewDidResignFirstResponder:(MVRoundedTextView*)roundedTextView;
- (BOOL)roundedTextView:(MVRoundedTextView*)roundedTextView
    doCommandBySelector:(SEL)selector;
@end

@interface MVRoundedTextView : TUIView

@property (readwrite) float maximumHeight;
@property (readwrite, nonatomic) float paddingLeft;
@property (readwrite, getter = isMultiline, nonatomic) BOOL multiline;
@property (readwrite, getter = isClosable, nonatomic) BOOL closable;
@property (readwrite, getter = isEditable, nonatomic) BOOL editable;
@property (strong, readwrite, nonatomic) NSString *text;
@property (strong, readwrite) NSString *placeholder;
@property (readwrite, getter = isAutocompletionEnabled) BOOL autocompletionEnabled;
@property (readwrite) int autocompletionTriggerCharCount;
@property (strong, readwrite) TUIView *additionalView;
@property (readonly) BOOL isFirstResponder;
@property (readwrite) BOOL animatesNextFirstResponder;
@property (readwrite, nonatomic) NSRange selectedRange;
@property (unsafe_unretained, readwrite) NSObject<MVRoundedTextViewCompletionSource>
                                         *completionSource;
@property (unsafe_unretained, readwrite) NSObject<MVRoundedTextViewDelegate> *delegate;

@end
