
#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
  SInt32 major = 0;
	SInt32 minor = 0;
	Gestalt(gestaltSystemVersionMajor, &major);
	Gestalt(gestaltSystemVersionMinor, &minor);
	if((major == 10 && minor >= 7) || major >= 11) {
		AtLeastLion = YES;
	}

  return NSApplicationMain(argc, (const char **)argv);
}
