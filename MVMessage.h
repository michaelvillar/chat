#import <Foundation/Foundation.h>

@protocol MVService;

@interface MVMessage : NSObject

@property (strong, readwrite) NSAttributedString *attributedString;
@property (strong, readwrite) NSObject <MVService> *service;

- (id)initWithAttributedString:(NSAttributedString*)attributedString;
- (id)initWithAttributedString:(NSAttributedString*)attributedString
                       service:(NSObject<MVService>*)service;

@end
