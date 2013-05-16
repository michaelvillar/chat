#import "NSDate+isSameDay.h"

@implementation NSDate (isSameDay)

- (NSDateComponents*)mv_components {
	return [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:self];
}

- (BOOL)mv_isSameDay:(NSDate*)date {
	NSDateComponents *comps = [self mv_components];
	NSDateComponents *comps2 = [date mv_components];
	return ([comps day] == [comps2 day] && [comps month] == [comps2 month] && [comps year] == [comps2 year]);
}


@end
