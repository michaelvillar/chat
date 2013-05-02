#import "NSEvent+CharacterDetection.h"

@implementation NSEvent (CharacterDetection)

- (BOOL)isCharacter:(unichar)aChar {
	return ([[self characters] rangeOfString:[NSString stringWithFormat:@"%C",aChar]].length > 0);
}

@end
