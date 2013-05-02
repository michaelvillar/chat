#import "MVMessage.h"
#import "MVService.h"

@implementation MVMessage

@synthesize attributedString      = attributedString_,
            service               = service_;

- (id)initWithAttributedString:(NSAttributedString*)attributedString
{
  return [self initWithAttributedString:attributedString service:nil];
}

- (id)initWithAttributedString:(NSAttributedString*)attributedString
                       service:(NSObject<MVService>*)service
{
  self = [super init];
  if(self)
  {
    attributedString_ = attributedString;
    service_ = service;
  }
  return self;
}

- (NSString*)description
{
  NSString *desc;
  if(self.service)
    desc = [NSString stringWithFormat:@"%@ (%@)",
            NSStringFromClass(self.service.class),
            self.service.url];
  else
    desc = [NSString stringWithString:self.attributedString.string];
  return desc;
}

@end
