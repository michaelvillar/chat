#import "MVRoundedTextView.h"
#import "MVGraphicsFunctions.h"
#import "MVShadow.h"

@interface TUITextEditor : TUITextRenderer @end
@interface TUITextViewEditor : TUITextEditor

@property (nonatomic, strong) NSDictionary *defaultAttributes;
@property (nonatomic, strong) NSDictionary *markedAttributes;

- (NSMutableAttributedString *)backingStore;
- (void)paste:(id)sender;
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange;

@end

@interface _MVRoundedTextViewEditor : TUITextViewEditor

@end

@interface _MVRoundedTextView : TUITextView

@property (strong, readwrite) MVRoundedTextView *roundedTextView;
@property (readwrite) BOOL multiline;
@property (readonly, nonatomic, getter = singleLine) BOOL singleLine;

@end

@implementation _MVRoundedTextViewEditor

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
  [super insertText:aString replacementRange:replacementRange];
  [((TUITextView*)(self.view)).delegate performSelector:@selector(textDidInserted)];
}

- (void)paste:(id)sender
{
  _MVRoundedTextView *textView = (_MVRoundedTextView*)(self.view);
	if([textView.roundedTextView respondsToSelector:@selector(paste:)])
  {
    if(![textView.roundedTextView performSelector:@selector(paste:) withObject:sender])
    {
      [super paste:sender];
    }
  }
  else
  {
    [super paste:sender];
  }
}

- (_MVRoundedTextView *)_mvRoundedTextView
{
	return (_MVRoundedTextView *)view;
}

- (void)insertTab:(id)sender
{
  if (!self._mvRoundedTextView.singleLine)
    [super insertTab:sender];
}

- (void)moveDown:(id)sender
{
	if (!self._mvRoundedTextView.singleLine)
    [super moveDown:sender];
}

- (void)insertNewline:(id)sender
{
	if (!self._mvRoundedTextView.singleLine)
    [super insertNewline:sender];
}

- (void)insertNewlineIgnoringFieldEditor:(id)sender
{
  if (!self._mvRoundedTextView.singleLine)
    [super insertNewlineIgnoringFieldEditor:sender];
}

- (void)cancelOperation:(id)sender
{
	if (self._mvRoundedTextView.singleLine)
    self._mvRoundedTextView.text = @"";
}

@end

@implementation _MVRoundedTextView

@synthesize roundedTextView     = roundedTextView_,
            multiline           = multiline_;

- (Class)textEditorClass
{
	return [_MVRoundedTextViewEditor class];
}

- (BOOL)singleLine {
  return !self.multiline;
}

@end

@interface MVRoundedTextView (Completion)

- (void)checkForAutocompletions;
- (void)checkForAutocompletionsForce:(BOOL)force;

@end

@interface MVRoundedTextView () <TUITextViewDelegate>

@property (strong, readwrite) TUIView *bottomView;
@property (strong, readwrite) TUIView *topView;
@property (strong, readwrite) TUIView *centerView;
@property (strong, readwrite) TUIScrollView *scrollView;
@property (strong, readwrite) _MVRoundedTextView *textView;
@property (strong, readwrite) TUIButton *closeButton;
@property (readwrite) int textViewHeight;
@property (readwrite) BOOL textViewHasFocus;
@property (readwrite) BOOL inCompletionMode;

- (void)refreshFocusAppearance:(BOOL)animated;
- (void)updateCloseButtonImage;
- (void)checkForFrame;

@end

void MVDrawBackground(MVRoundedTextView *chatTextView, CGRect rect, float h);
void MVDrawBackground(MVRoundedTextView *chatTextView, CGRect rect, float h) {
  CGRect rrect = CGRectMake(3, rect.origin.y + 4, rect.size.width - 6, h - 8);
  NSBezierPath *path = MVRoundedRectBezierPath(rrect, 11);
  NSBezierPath *path2;
  NSBezierPath *path3;
  NSAffineTransform *transform;
  NSShadow *shadow;

  // white shadow (bottom)
  [[NSGraphicsContext currentContext] saveGraphicsState];
  path2 = [NSBezierPath bezierPath];
  path2.windingRule = NSEvenOddWindingRule;
  [path2 appendBezierPath:path];

  path3 = [NSBezierPath bezierPath];
  [path3 appendBezierPath:path];
  transform = [NSAffineTransform transform];
  [transform translateXBy:0 yBy:-1];
  [path3 transformUsingAffineTransform:transform];

  [path2 appendBezierPath:path3];
  [[NSColor colorWithDeviceWhite:1 alpha:0.25] set];
  [path2 fill];
  [[NSGraphicsContext currentContext] restoreGraphicsState];

  // black shadow (top)
  [[NSGraphicsContext currentContext] saveGraphicsState];
  path2 = [NSBezierPath bezierPath];
  path2.windingRule = NSEvenOddWindingRule;
  [path2 appendBezierPath:path];

  path3 = [NSBezierPath bezierPath];
  [path3 appendBezierPath:path];
  transform = [NSAffineTransform transform];
  [transform translateXBy:0 yBy:1];
  [path3 transformUsingAffineTransform:transform];

  [path2 appendBezierPath:path3];
  [[NSColor colorWithDeviceWhite:0 alpha:0.05] set];
  [path2 fill];
  [[NSGraphicsContext currentContext] restoreGraphicsState];

  if(chatTextView.textViewHasFocus && chatTextView.windowHasFocus) {
    // blue blur
    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSColor *blue = [NSColor colorWithDeviceRed:0.2588 green:0.5608 blue:0.8471 alpha:1];
    [blue set];
    shadow = [[MVShadow alloc] init];
    shadow.shadowBlurRadius = 4.0;
    shadow.shadowColor = blue;
    [shadow set];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }
  else {
    // grey background
    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSColor *startColor = [NSColor colorWithDeviceWhite:0 alpha:0.1];
    NSColor *endColor = [NSColor colorWithDeviceWhite:0 alpha:0.2];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInBezierPath:path angle:90];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }

  // white background
  [[NSGraphicsContext currentContext] saveGraphicsState];
  rrect = CGRectMake(4.2, rect.origin.y + 5, rect.size.width - 8.4, h - 10);
  path2 = MVRoundedRectBezierPath(rrect, 9.8);
  [[NSColor whiteColor] set];
  [path2 fill];
  [[NSGraphicsContext currentContext] restoreGraphicsState];

  // overall shadow
  [[NSGraphicsContext currentContext] saveGraphicsState];
  [path setClip];
  shadow = [[MVShadow alloc] init];
  shadow.shadowBlurRadius = 3.0;
  if(chatTextView.textViewHasFocus && chatTextView.windowHasFocus) {
    shadow.shadowColor = [NSColor colorWithDeviceRed:0.4392 green:0.5569 blue:0.7098 alpha:1];
    [[NSColor colorWithDeviceRed:0.4627 green:0.6196 blue:0.7765 alpha:1.0000] set];
  }
  else {
    shadow.shadowColor = [NSColor colorWithDeviceWhite:0 alpha:0.25];
    [[NSColor colorWithDeviceRed:0.5922 green:0.5961 blue:0.6000 alpha:1.0000] setStroke];
  }
  shadow.shadowOffset = NSMakeSize(0, -1);
  [shadow set];
  [path stroke];
  [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@implementation MVRoundedTextView

@synthesize bottomView            = bottomView_,
            topView               = topView_,
            centerView            = centerView_,
            scrollView            = scrollView_,
            textViewHeight        = textViewHeight_,
            textViewHasFocus      = textViewHasFocus_,
            inCompletionMode      = inCompletionMode_,
            autocompletionEnabled = autocompletionEnabled_,
            autocompletionTriggerCharCount = autocompletionTriggerCharCount_,
            textView              = textView_,
            closeButton           = closeButton_,
            maximumHeight         = maximumHeight_,
            paddingLeft           = paddingLeft_,
            multiline             = multiline_,
            closable              = closable_,
            placeholder           = placeholder_,
            additionalView        = additionalView_,
            completionSource      = completionSource_,
            animatesNextFirstResponder  = animatesNextFirstResponder_,
            delegate              = delegate_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self) {
    __block MVRoundedTextView *parent = self;

    self.opaque = NO;
    self.backgroundColor = [TUIColor clearColor];
    self.shouldDisplayWhenWindowChangesFocus = YES;
    [self addObserver:self
           forKeyPath:@"windowHasFocus"
              options:NSKeyValueObservingOptionNew
              context:NULL];

    maximumHeight_ = 100;
    textViewHeight_ = 15;
    completionSource_ = nil;
    delegate_ = nil;
    textViewHasFocus_ = NO;
    inCompletionMode_ = NO;
    paddingLeft_ = 0;
    multiline_ = YES;
    closable_ = NO;
    placeholder_ = @"";
    additionalView_ = nil;
    closeButton_ = nil;
    animatesNextFirstResponder_ = YES;
    autocompletionEnabled_ = NO;
    autocompletionTriggerCharCount_ = 1;

    bottomView_ = [[TUIView alloc] initWithFrame:CGRectZero];
    bottomView_.backgroundColor = [TUIColor clearColor];
    bottomView_.drawRect = ^(TUIView *view, CGRect rect) {
      MVDrawBackground(parent, rect, 26);
    };
    [self addSubview:bottomView_];

    centerView_ = [[TUIView alloc] initWithFrame:CGRectZero];
    centerView_.backgroundColor = [TUIColor clearColor];
    centerView_.drawRect = ^(TUIView *view, CGRect rect) {
      CGRect rrect = CGRectMake(0, -13, rect.size.width, rect.size.height);
      MVDrawBackground(parent, rrect, rect.size.height + 26);
    };
    [self addSubview:centerView_];

    topView_ = [[TUIView alloc] initWithFrame:CGRectZero];
    topView_.backgroundColor = [TUIColor clearColor];
    topView_.drawRect = ^(TUIView *view, CGRect rect) {
      CGRect rrect = CGRectMake(0, -13, rect.size.width, rect.size.height);
      MVDrawBackground(parent, rrect, 26);
    };
    [self addSubview:topView_];

    CGRect rect = CGRectMake(12, 7, self.bounds.size.width - 24, self.bounds.size.height - 8);
    CGRect scrollViewFrame = CGRectMake(12, 7,
                                        self.bounds.size.width - 18,
                                        self.bounds.size.height - 8);
    scrollView_ = [[TUIScrollView alloc] initWithFrame:scrollViewFrame];
    textView_ = [[_MVRoundedTextView alloc] initWithFrame:CGRectMake(0, 0,
                                                                      rect.size.width,
                                                                      rect.size.height)];
    textView_.multiline = YES;
    textView_.roundedTextView = self;
    textView_.delegate = self;
    textView_.backgroundColor = [TUIColor clearColor];
    textView_.drawFrame = ^(TUIView * view, CGRect rect) {
      [[NSColor whiteColor] set];
      [NSBezierPath fillRect:CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height - 2)];

      if(parent.textView.text.length <= 0 && [parent.placeholder length] > 0)
      {
        CGRect rect = CGRectMake(0, 1,
                                 view.frame.size.width - 12 - parent.paddingLeft - 5, 15);
        NSColor *fontColor = (parent.textViewHasFocus ?
                              [NSColor colorWithDeviceRed:0.6902 green:0.7294 blue:0.7804 alpha:1] :
                              [NSColor colorWithDeviceRed:0.6980 green:0.6980 blue:0.6980 alpha:1]);
        MVDrawString(parent.placeholder,
                      rect,
                      fontColor,
                      12, kMVStringTypeNormal, nil, CGSizeZero, 0);
      }
    };
    textView_.subpixelTextRenderingEnabled = YES;
    textView_.font = [TUIFont systemFontOfSize:12];
    textView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;

    scrollView_.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
    scrollView_.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
    scrollView_.scrollEnabled = YES;
    scrollView_.clipsToBounds = YES;
    [scrollView_ setContentSize:textView_.bounds.size];
    [scrollView_ addSubview:textView_];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(textRendererDidBecomeFirstResponder:)
               name:TUITextRendererDidBecomeFirstResponder
             object:nil];
    [nc addObserver:self
           selector:@selector(textRendererDidResignFirstResponder:)
               name:TUITextRendererDidResignFirstResponder
             object:nil];

    [self addSubview:scrollView_];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeObserver:self forKeyPath:@"windowHasFocus"];
}

- (BOOL)acceptsFirstResponder
{
  if(self.isFirstResponder)
    return NO;
  return YES;
}

- (BOOL)becomeFirstResponder
{
  [self.nsWindow tui_makeFirstResponder:[self.textView.textRenderers objectAtIndex:0]];
  return YES;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  [self checkForFrame];

  float scrollViewWidth = self.bounds.size.width - 18 - self.paddingLeft -
                          (self.isClosable ? 20 : 0);
  CGRect scrollViewFrame = CGRectMake(12 + self.paddingLeft, 7,
                                      scrollViewWidth, self.textViewHeight);
  CGRect frame = self.frame;
  [self.bottomView setFrame:CGRectMake(0, 0, frame.size.width, 13)];

  [self.centerView removeAllAnimations];
  [self.topView removeAllAnimations];
  [self.scrollView removeAllAnimations];

  BOOL animated = NO;
  if(self.centerView.frame.size.width != frame.size.width) {
    [self.scrollView setFrame:scrollViewFrame];
    [self.centerView setFrame:CGRectMake(0, 13, frame.size.width, frame.size.height - 26)];
    [self.topView setFrame:CGRectMake(0, frame.size.height - 13, frame.size.width, 13)];
  }
  else {
    animated = YES;
    [TUIView animateWithDuration:0.2
    animations:^{
      [self.scrollView setFrame:scrollViewFrame];
      [self.centerView setFrame:CGRectMake(0, 13, frame.size.width, frame.size.height - 26)];
      [self.topView setFrame:CGRectMake(0, frame.size.height - 13, frame.size.width, 13)];
    }];
  }

  if([self.delegate respondsToSelector:@selector(roundedTextViewDidResize:animated:)])
    [self.delegate roundedTextViewDidResize:self
                                animated:animated];
}

#pragma mark -
#pragma mark Properties

- (void)setPaddingLeft:(float)paddingLeft
{
  if(paddingLeft == paddingLeft_)
    return;
  paddingLeft_ = paddingLeft;
  [self setNeedsLayout];
}

- (void)setMultiline:(BOOL)multiline
{
  if(multiline == multiline_)
    return;
  multiline_ = multiline;
  self.textView.multiline = multiline;
}

- (void)setEditable:(BOOL)editable
{
  self.textView.editable = editable;
  self.layer.opacity = (editable ? 1 : 0.5);
}

- (BOOL)isEditable
{
  return self.textView.editable;
}

- (void)setClosable:(BOOL)closable
{
  if(closable == closable_)
    return;
  closable_ = closable;
  [self setNeedsLayout];

  if(closable)
  {
    if(!self.closeButton)
    {
      self.closeButton = [[TUIButton alloc] initWithFrame:CGRectZero];
      self.closeButton.autoresizingMask = TUIViewAutoresizingFlexibleLeftMargin;
      [self updateCloseButtonImage];
      [self.closeButton setImage:[TUIImage imageNamed:@"icon_searchfield_close_active.png"
                                                cache:YES]
                        forState:TUIControlStateHighlighted];
      self.closeButton.dimsInBackground = NO;
      [self.closeButton addTarget:self
                           action:@selector(closeButtonAction)
                 forControlEvents:TUIControlEventTouchUpInside];
    }
    self.closeButton.frame = CGRectMake(self.bounds.size.width - 21, 8, 13, 13);
    [self addSubview:self.closeButton];
  }
  else
    [self.closeButton removeFromSuperview];
}

- (BOOL)isFirstResponder
{
  return [self.textView.textRenderers objectAtIndex:0] == self.nsWindow.firstResponder;
}

- (NSString*)text
{
  return self.textView.text;
}

- (void)setText:(NSString *)text
{
  self.textView.text = text;
}

- (NSRange)selectedRange
{
  return self.textView.selectedRange;
}

- (void)setSelectedRange:(NSRange)selectedRange
{
  self.textView.selectedRange = selectedRange;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([keyPath isEqualToString:@"windowHasFocus"])
  {
    if(self.isFirstResponder)
      [self refreshFocusAppearance:NO];
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark Event Handling

- (BOOL)paste:(id)sender
{
  if([self.delegate respondsToSelector:@selector(roundedTextView:pastePasteboard:)])
    return [self.delegate roundedTextView:self pastePasteboard:[NSPasteboard generalPasteboard]];
  return NO;
}

#pragma mark -
#pragma mark Private Methods

- (void)refreshFocusAppearance:(BOOL)animated
{
  if(!self.animatesNextFirstResponder)
    animated = NO;
  self.animatesNextFirstResponder = YES;
  [TUIView setAnimationsEnabled:animated block:^{
    [TUIView animateWithDuration:0.2 animations:^{
      [self.topView redraw];
      [self.bottomView redraw];
      [self.centerView redraw];
      [self updateCloseButtonImage];
      if(self.additionalView)
        [self.additionalView redraw];
    }];
  }];
}

- (void)updateCloseButtonImage
{
  if(!self.closeButton)
    return;
  [self.closeButton setImage:[TUIImage imageNamed:(self.textViewHasFocus ?
                                                   @"icon_searchfield_close.png" :
                                                   @"icon_searchfield_close_unfocused.png")
                                            cache:YES]
                    forState:TUIControlStateNormal];
}

- (void)checkForFrame
{
  NSSize size = NSMakeSize(0, 15);
  float height;
  if(self.multiline)
  {
    size = [[self.textView.textRenderers objectAtIndex:0]
                    sizeConstrainedToWidth:self.textView.bounds.size.width];
    height = size.height;
    if(height < 15)
      height = 15;
    if(height > self.maximumHeight - 14)
      height = self.maximumHeight - 14;
    if(height != self.textViewHeight) {
      self.textViewHeight = height;

      CGRect frame = self.frame;
      frame.size.height = self.textViewHeight + 14;
      [self setFrame:frame];
    }
    if(size.height < 15)
      size.height = 15;
    size.width = self.textView.bounds.size.width;
  }
  else
  {
    size.width = 1000;
  }
  [self.textView setFrame:CGRectMake(0, 0, size.width, size.height)];
  [self.scrollView setContentSize:self.textView.bounds.size];
}

#pragma mark -
#pragma mark Button Actions

- (void)closeButtonAction
{
  self.textView.text = @"";
  if([self.delegate respondsToSelector:@selector(roundedTextViewCancelOperation:)])
  {
    [self.delegate roundedTextViewCancelOperation:self];
  }
}

#pragma mark -
#pragma mark Methods called by custom TextViewEditor

- (void)textDidInserted
{
  [self checkForAutocompletions];
}

#pragma mark -
#pragma mark TUITextFieldDelegate Methods

- (void)textViewDidChange:(TUITextView *)textView
{
  [self willChangeValueForKey:@"text"];
  [self didChangeValueForKey:@"text"];
  [self checkForFrame];
  if([self.delegate respondsToSelector:@selector(roundedTextViewTextDidChange:)])
    [self.delegate roundedTextViewTextDidChange:self];
}

- (BOOL)textView:(TUITextView *)textView doCommandBySelector:(SEL)commandSelector
{
  if([self.delegate respondsToSelector:@selector(roundedTextView:doCommandBySelector:)])
  {
    BOOL res = [self.delegate roundedTextView:self doCommandBySelector:commandSelector];
    if(res)
      return YES;
  }
  if(self.inCompletionMode &&
     (commandSelector == @selector(insertNewline:) || commandSelector == @selector(insertTab:)))
  {
    self.textView.selectedRange = NSMakeRange(self.textView.selectedRange.location +
                                              self.textView.selectedRange.length, 0);
    self.inCompletionMode = NO;
    return YES;
  }
  else if(commandSelector == @selector(insertTab:) && !self.inCompletionMode)
  {
    [self checkForAutocompletionsForce:YES];
    return YES;
  }
  else if(commandSelector == @selector(insertNewline:))
  {
    if([self.delegate respondsToSelector:@selector(roundedTextView:sendString:)])
    {
      NSString *string = self.textView.text;
      BOOL shouldClear = [self.delegate roundedTextView:self sendString:string];
      if(shouldClear)
        self.textView.text = @"";
      return YES;
    }
  }
  else if(commandSelector == @selector(cancelOperation:))
  {
    if(self.inCompletionMode)
    {
      NSMutableString *text = [NSMutableString stringWithString:self.text];
      [text replaceCharactersInRange:self.textView.selectedRange withString:@""];

      self.textView.selectedRange = NSMakeRange(self.textView.selectedRange.location, 0);
      self.textView.text = text;
      self.inCompletionMode = NO;
    }
    else
    {
      BOOL r = NO;
      if(self.isClosable)
      {
        self.textView.text = @"";
        r = YES;
      }
      if([self.delegate respondsToSelector:@selector(roundedTextViewCancelOperation:)])
      {
        [self.delegate roundedTextViewCancelOperation:self];
        r = YES;
      }
      return r;
    }
  }
  else if(commandSelector == @selector(moveUp:))
  {
    if(self.textView.selectedRange.location == 0 &&
       self.textView.selectedRange.length == 0)
    {
      if([self.delegate respondsToSelector:@selector(roundedTextViewMoveUp:)])
        [self.delegate roundedTextViewMoveUp:self];
    }
  }
  return NO;
}

#pragma mark -
#pragma mark TUITextRendererDelegate Methods

- (void)textRendererDidResignFirstResponder:(NSNotification *)notification
{
  if(![self.textView.textRenderers containsObject:notification.object])
    return;
  self.textViewHasFocus = NO;
  [self refreshFocusAppearance:YES];
  if([self.delegate respondsToSelector:@selector(roundedTextViewDidResignFirstResponder:)])
    [self.delegate roundedTextViewDidResignFirstResponder:self];
}

- (void)textRendererDidBecomeFirstResponder:(NSNotification *)notification
{
  if(![self.textView.textRenderers containsObject:notification.object])
    return;
  self.textViewHasFocus = YES;
  [self refreshFocusAppearance:YES];
  if([self.delegate respondsToSelector:@selector(roundedTextViewDidBecomeFirstResponder:)])
    [self.delegate roundedTextViewDidBecomeFirstResponder:self];
}

#pragma mark -
#pragma mark Drag And Drop support

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
  return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
  return [self draggingEntered:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  NSPasteboard *pboard = sender.draggingPasteboard;
  if([self.delegate respondsToSelector:@selector(roundedTextView:didDropPasteboard:)])
    return [self.delegate roundedTextView:self didDropPasteboard:pboard];
  return NO;
}

@end

@implementation MVRoundedTextView (Completion)

- (void)checkForAutocompletions
{
  [self checkForAutocompletionsForce:NO];
}

- (void)checkForAutocompletionsForce:(BOOL)force
{
  if(!self.isAutocompletionEnabled)
    return;
  if(!self.completionSource)
  {
    self.inCompletionMode = NO;
    return;
  }
  NSMutableString *text = [NSMutableString stringWithString:self.text];
  NSRange selectedRange = self.textView.selectedRange;

  NSString *pattern = @"(?<![^ ]{1})(@)";
  NSRegularExpression *regex = [NSRegularExpression
                                regularExpressionWithPattern:pattern
                                options:NSRegularExpressionCaseInsensitive
                                error:nil];

  if(!regex)
  {
    self.inCompletionMode = NO;
    return;
  }

  NSArray *matches = [regex matchesInString:text
                                    options:0
                                      range:NSMakeRange(0, selectedRange.location)];
  if(matches.count <= 0)
  {
    self.inCompletionMode = NO;
    return;
  }

  NSTextCheckingResult *match = [matches lastObject];
  NSRange firstDemarkerRange = [match rangeAtIndex:1];
  if(firstDemarkerRange.location == NSNotFound)
  {
    self.inCompletionMode = NO;
    return;
  }

  NSRange toBeCompletedRange = NSMakeRange(firstDemarkerRange.location + 1,
                                           selectedRange.location- firstDemarkerRange.location - 1);
  NSString *substring = [text substringWithRange:toBeCompletedRange];
  if(substring.length < self.autocompletionTriggerCharCount && !force)
  {
    self.inCompletionMode = NO;
    return;
  }
  NSArray *completions = [self.completionSource roundedTextView:self
                                        completionsForSubstring:substring];

  if(completions.count > 0)
  {
    NSString *completionString = [completions objectAtIndex:0];
    NSRange range = NSMakeRange(firstDemarkerRange.location + 1,
                                selectedRange.location + selectedRange.length -
                                (firstDemarkerRange.location + 1));

    int from = selectedRange.location - firstDemarkerRange.location - 1;
    [text replaceCharactersInRange:selectedRange
                        withString:[completionString substringWithRange:
                                    NSMakeRange(from, completionString.length - from)]];
    self.textView.text = text;
    self.textView.selectedRange = NSMakeRange(selectedRange.location,
                                              completionString.length -
                                              (selectedRange.location - range.location));
    self.inCompletionMode = YES;
  }
  else
  {
    self.inCompletionMode = NO;
  }
}

@end