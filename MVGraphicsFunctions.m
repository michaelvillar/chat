#import "MVGraphicsFunctions.h"
#import "MVShadow.h"


CGImageRef MVCreateNoiseImageRef(NSUInteger width, NSUInteger height, CGFloat factor)
{
  NSUInteger size = width*height;
  char *rgba = (char *)malloc(size); srand(124);
  for(NSUInteger i=0; i < size; ++i){rgba[i] = rand()%256*factor;}
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
  CGContextRef bitmapContext =
  CGBitmapContextCreate(rgba, width, height, 8, width, colorSpace, kCGImageAlphaNone);
  CFRelease(colorSpace);
  free(rgba);
  CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
  CFRelease(bitmapContext);
  return image;
}

NSBezierPath* MVRoundedRectBezierPath(CGRect rrect, CGFloat radius)
{
  if(rrect.size.width == 0 || rrect.size.height == 0 ||
     rrect.origin.x == INFINITY || rrect.origin.y == INFINITY)
    return [NSBezierPath bezierPathWithRect:CGRectZero];
  NSBezierPath *path = [NSBezierPath bezierPath];
  CGFloat minx = CGRectGetMinX(rrect);
	CGFloat midx = CGRectGetMidX(rrect);
	CGFloat maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect);
	CGFloat midy = CGRectGetMidY(rrect);
	CGFloat maxy = CGRectGetMaxY(rrect);
  [path moveToPoint:CGPointMake(minx, midy)];
  [path appendBezierPathWithArcFromPoint:CGPointMake(minx, miny)
                                 toPoint:CGPointMake(midx, miny)
                                  radius:radius];
  [path appendBezierPathWithArcFromPoint:CGPointMake(maxx, miny)
                                 toPoint:CGPointMake(maxx, midy)
                                  radius:radius];
  [path appendBezierPathWithArcFromPoint:CGPointMake(maxx, maxy)
                                 toPoint:CGPointMake(midx, maxy)
                                  radius:radius];
  [path appendBezierPathWithArcFromPoint:CGPointMake(minx, maxy)
                                 toPoint:CGPointMake(minx, midy)
                                  radius:radius];
  [path closePath];
  return path;
}

NSFont* MVFontFromStyle(float fontSize, int style)
{
  if(style == kMVStringTypeMedium)
    return [NSFont fontWithName:@"Helvetica Neue Medium" size:fontSize];
  if(style == kMVStringTypeBold)
    return [NSFont fontWithName:@"Helvetica Neue Bold" size:fontSize];
  return [NSFont fontWithName:@"Helvetica Neue" size:fontSize];
}

#pragma mark -int style
#pragma mark String Drawing Methods

NSSize MVSizeOfString (NSString *string, float fontSize, int style)
{
	NSDictionary* dict = MVDictionaryForStringDrawing(fontSize, style);
	NSSize size = [string sizeWithAttributes:dict];
	return size;
}

NSDictionary* MVDictionaryForStringDrawing (float fontSize, int style)
{
	NSDictionary *dict = [[NSMutableDictionary alloc] init];
  [dict setValue:MVFontFromStyle(fontSize, style) forKey:NSFontAttributeName];
	return dict;
}

void MVDrawString (NSString *string, NSRect aRect, NSColor* fontColor, float fontSize,
                   int style, NSColor* shadowColor, NSSize shadowOffset, float shadowBlur)
{
	MVDrawStringAlign(string, aRect, fontColor, fontSize, style,
                     shadowColor, shadowOffset, shadowBlur, 0);
}

void MVDrawStringAlignLineBreakMode (NSString *string, NSRect aRect, NSColor* fontColor,
                                     float fontSize, int style, NSColor* shadowColor,
                                     NSSize shadowOffset, float shadowBlur,
                                     int alignment, int lineBreakMode)
{
	NSDictionary* dict = MVDictionaryForStringDrawing(fontSize, bold);
	NSShadow *shadow = nil;
	if(shadowColor != nil) {
		shadow = [[MVShadow alloc] init];
		[shadow setShadowOffset:shadowOffset];
		[shadow setShadowBlurRadius:shadowBlur];
		[shadow setShadowColor:shadowColor];
	}

	NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
	if(alignment == 1)
		[pStyle setAlignment:NSCenterTextAlignment];
	else if(alignment == 2)
		[pStyle setAlignment:NSRightTextAlignment];
	[pStyle setLineBreakMode:lineBreakMode];
	[dict setValue:pStyle forKey:NSParagraphStyleAttributeName];
	[dict setValue:fontColor forKey:NSForegroundColorAttributeName];
  
  [dict setValue:MVFontFromStyle(fontSize, style) forKey:NSFontAttributeName];

	[NSGraphicsContext saveGraphicsState];
	if(shadow)
		[shadow set];

	[string drawInRect:aRect withAttributes:dict];

	[NSGraphicsContext restoreGraphicsState];
}

void MVDrawStringAlign (NSString *string, NSRect aRect, NSColor* fontColor, float fontSize,
                        int style, NSColor* shadowColor, NSSize shadowOffset, float shadowBlur,
                         int alignment)
{
	MVDrawStringAlignLineBreakMode(string, aRect, fontColor, fontSize, style, shadowColor,
                                 shadowOffset, shadowBlur, alignment, NSLineBreakByTruncatingTail);
}

void MVDrawAttributedStringWithColor(NSAttributedString *string, NSRect aRect, NSColor* fontColor,
                                      NSColor* shadowColor, NSSize shadowOffset, int alignment,
                                      int lineBreakMode)
{
	NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
	NSShadow *shadow = nil;
	if(shadowColor != nil) {
		shadow = [[MVShadow alloc] init];
		[shadow setShadowOffset:shadowOffset];
		[shadow setShadowBlurRadius:1.0];
		[shadow setShadowColor:shadowColor];
	}

	[NSGraphicsContext saveGraphicsState];
	if(shadow)
		[shadow set];

  NSMutableParagraphStyle *style = [[mutableString attribute:NSParagraphStyleAttributeName
                                                     atIndex:0
                                              effectiveRange:NULL] mutableCopy];
	if(alignment == 1)
		[style setAlignment:NSCenterTextAlignment];
	else if(alignment == 2)
		[style setAlignment:NSRightTextAlignment];
	[style setLineBreakMode:lineBreakMode];

  if(fontColor)
  {
    [mutableString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                  fontColor,NSForegroundColorAttributeName,
                                  nil]
                           range:NSMakeRange(0, [mutableString length])];
  }
	[mutableString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                style,NSParagraphStyleAttributeName,
                                nil]
                         range:NSMakeRange(0, [mutableString length])];

	[mutableString drawInRect:aRect];

	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark -
#pragma mark Window Chrome

void MVDrawWindowTitleBar (CGRect drawingRect, NSWindow *window)
{
  BOOL drawsAsMainWindow = ([window isMainWindow] &&
                            [[NSApplication sharedApplication] isActive]);
  NSColor *startColor = drawsAsMainWindow ? IN_COLOR_MAIN_START_L : IN_COLOR_NOTMAIN_START_L;
  NSColor *endColor = drawsAsMainWindow ? IN_COLOR_MAIN_END_L : IN_COLOR_NOTMAIN_END_L;
  NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
  [gradient drawInRect:drawingRect angle:90];

  if (drawsAsMainWindow) {
    static CGImageRef noisePattern = nil;
    if (noisePattern == nil) noisePattern = MVCreateNoiseImageRef(128, 128, 0.015);
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
    CGRect noisePatternRect = CGRectZero;
    noisePatternRect.size = CGSizeMake(CGImageGetWidth(noisePattern),
                                       CGImageGetHeight(noisePattern));
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawTiledImage(context, noisePatternRect, noisePattern);
    [NSGraphicsContext restoreGraphicsState];
  }

}
