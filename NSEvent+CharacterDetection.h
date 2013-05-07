#import <Cocoa/Cocoa.h>

@interface NSEvent (CharacterDetection)

- (BOOL)isCharacter:(unichar)aChar;
- (BOOL)isDigit;
- (BOOL)isChar;

@end
