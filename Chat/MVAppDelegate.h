#import <Cocoa/Cocoa.h>

@interface MVAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

#pragma mark Menu Actions
- (IBAction)newTab:(id)sender;
- (IBAction)previousTab:(id)sender;
- (IBAction)nextTab:(id)sender;
- (IBAction)closeTab:(id)sender;
- (IBAction)openPreferences:(id)sender;

@end
