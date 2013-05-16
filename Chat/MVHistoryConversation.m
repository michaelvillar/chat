#import "MVHistoryConversation.h"
#import "NSDate+isSameDay.h"

@interface MVHistoryConversation ()

@property (strong, readwrite) XMPPJID *jid;
@property (strong, readwrite) NSMutableOrderedSet *unsavedMessages;
@property (strong, readwrite) NSDateFormatter *dateFormatter;
@property (strong, readonly, nonatomic) NSString *path;
@property (strong, readwrite) NSDate *dateForPath;

@end

@implementation MVHistoryConversation

@synthesize jid = jid_,
            unsavedMessages = unsavedMessages_,
            dateFormatter = dateFormatter_,
            path = path_,
            dateForPath = dateForPath_;

- (id)initWithJid:(XMPPJID*)jid
{
  self = [super init];
  if(self)
  {
    jid_ = jid;
    unsavedMessages_ = [NSMutableOrderedSet orderedSet];
    dateFormatter_ = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d"
                                            allowNaturalLanguage:NO];
    path_ = nil;
    dateForPath_ = nil;
  }
  return self;
}

- (void)saveMessage:(XMPPMessage*)message
{
  XMPPMessage *copiedMessage = message.copy;
  NSMutableArray *children = [NSMutableArray arrayWithArray:copiedMessage.children];
  for(NSXMLNode* node in copiedMessage.children)
  {
    if(![node.name isEqualToString:@"body"])
      [children removeObject:node];
  }
  [copiedMessage setChildren:children];
  NSXMLElement *timestampElement = [NSXMLElement elementWithName:@"timestamp"];
  [timestampElement setStringValue:[NSString stringWithFormat:@"%f",
                                    [[NSDate date] timeIntervalSince1970]]];
  [copiedMessage addChild:timestampElement];
  [self.unsavedMessages addObject:copiedMessage];
  [self saveToDisk];
}

- (void)saveToDisk
{
  NSMutableString *string = [NSMutableString string];
  for(XMPPMessage *message in self.unsavedMessages)
  {
    [string appendString:[message XMLString]];
  }
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  
  NSFileManager *fm = [NSFileManager defaultManager];

  NSError *error;
  [fm createDirectoryAtPath:[self.path stringByDeletingLastPathComponent]
withIntermediateDirectories:YES
                 attributes:nil error:&error];
  
  if(![fm fileExistsAtPath:self.path])
  {
    [fm createFileAtPath:self.path contents:data attributes:nil];
  }
  else if([fm isWritableFileAtPath:self.path])
  {
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:self.path];
    if(!error)
    {
      [fh seekToEndOfFile];
      [fh writeData:data];
      [fh closeFile];
    }
  }
  [self.unsavedMessages removeAllObjects];
}

#pragma mark Private Properties

- (NSString*)path
{
  if(!path_ || !self.dateForPath || ![self.dateForPath mv_isSameDay:[NSDate date]])
  {
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet
                                                 characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    NSString *bareJid = [[self.jid.bare componentsSeparatedByCharactersInSet:illegalFileNameCharacters]
                         componentsJoinedByString:@""];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *filePath = [paths objectAtIndex:0];
    filePath = [filePath stringByAppendingPathComponent:@"Chat"];
    
    NSString *path = [NSString stringWithFormat:
                      @"%@/%@/%@.conversation",
                      filePath,
                      bareJid,
                      [self.dateFormatter stringFromDate:[NSDate date]]];
    path_ = path;
    self.dateForPath = [NSDate date];
  }
  return path_;
}

@end
