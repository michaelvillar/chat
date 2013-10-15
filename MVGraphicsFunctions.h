#import <Cocoa/Cocoa.h>
#define kMVSplitViewBorderColor [NSColor colorWithDeviceRed:0.7529 green:0.7725 blue:0.8078 alpha:1]

CGImageRef MVCreateNoiseImageRef(NSUInteger width, NSUInteger height, CGFloat factor);
NSBezierPath* MVRoundedRectBezierPath(CGRect rrect, CGFloat radius);

#pragma mark -
#pragma mark String Drawing Methods
NSSize MVSizeOfString (NSString *string, float fontSize, int style);
NSDictionary* MVDictionaryForStringDrawing (float fontSize, int style);
#define kMVStringTypeNormal 0
#define kMVStringTypeMedium 1
#define kMVStringTypeBold 2
void MVDrawString (NSString *string, NSRect aRect, NSColor* fontColor, float fontSize,
                   int style, NSColor* shadowColor, NSSize shadowOffset, float shadowBlur);
void MVDrawStringAlignLineBreakMode (NSString *string, NSRect aRect, NSColor* fontColor,
                                      float fontSize, int style, NSColor* shadowColor,
                                      NSSize shadowOffset, float shadowBlur,
                                      int alignment, int lineBreakMode);
void MVDrawStringAlign (NSString *string, NSRect aRect, NSColor* fontColor, float fontSize,
                        int style, NSColor* shadowColor, NSSize shadowOffset,
                         float shadowBlur, int alignment);
void MVDrawAttributedStringWithColor(NSAttributedString *string, NSRect aRect, NSColor* fontColor,
                                      NSColor* shadowColor, NSSize shadowOffset, int alignment,
                                      int lineBreakMode);

#pragma mark -
#pragma mark Window Chrome

#define IN_COLOR_MAIN_START_L [NSColor colorWithDeviceWhite:0.66 alpha:1.0]
#define IN_COLOR_MAIN_END_L [NSColor colorWithDeviceWhite:0.9 alpha:1.0]
#define IN_COLOR_MAIN_BOTTOM_L [NSColor colorWithDeviceWhite:0.408 alpha:1.0]

#define IN_COLOR_NOTMAIN_START_L [NSColor colorWithDeviceWhite:0.878 alpha:1.0]
#define IN_COLOR_NOTMAIN_END_L [NSColor colorWithDeviceWhite:0.976 alpha:1.0]
#define IN_COLOR_NOTMAIN_BOTTOM_L [NSColor colorWithDeviceWhite:0.655 alpha:1.0]

void MVDrawWindowTitleBar (CGRect drawingRect, NSWindow *window);