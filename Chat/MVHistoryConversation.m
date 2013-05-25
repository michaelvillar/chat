#import "MVHistoryConversation.h"
#import "NSDate+isSameDay.h"

#define kMVHistoryFileExtension @"conversation"

@interface MVHistoryConversation ()

@property (strong, readwrite) XMPPJID *jid;
@property (strong, readwrite) NSMutableOrderedSet *unsavedMessages;
@property (strong, readwrite) NSDateFormatter *dateFormatter;
@property (strong, readonly, nonatomic) NSString *directoryPath;
@property (strong, readonly, nonatomic) NSString *path;
@property (strong, readwrite) NSDate *dateForPath;

@end

@implementation MVHistoryConversation

@synthesize jid = jid_,
            unsavedMessages = unsavedMessages_,
            dateFormatter = dateFormatter_,
            directoryPath = directoryPath_,
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
    directoryPath_ = nil;
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

- (NSOrderedSet*)messagesWithLimit:(NSUInteger)limit
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error;
  NSArray *files = [fm contentsOfDirectoryAtPath:self.directoryPath error:&error];
  NSMutableOrderedSet *messages = [NSMutableOrderedSet orderedSet];
  if(error)
    return messages;
  NSMutableOrderedSet *mFiles = [NSMutableOrderedSet orderedSet];
  for(NSString *file in files)
  {
    if([file.pathExtension isEqualToString:kMVHistoryFileExtension])
      [mFiles addObject:file];
  }
  [mFiles sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    return [obj2 compare:obj1];
  }];
  if(mFiles.count > 0)
  {
    NSUInteger messagesCount = 0;
    for(NSString *file in mFiles)
    {
      NSString *xmlString = [NSString stringWithContentsOfFile:
                             [self.directoryPath stringByAppendingPathComponent:file]
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
      xmlString = [NSString stringWithFormat:
                   @"<?xml version=\"1.0\"?><messages>%@</messages>", xmlString];
      NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:xmlString options:0 error:&error];
      NSMutableOrderedSet *messagesBatch = [NSMutableOrderedSet orderedSet];
      for(NSXMLElement *element in doc.rootElement.children)
      {
        XMPPMessage *message = [XMPPMessage messageFromElement:element];
        [messagesBatch addObject:message];
        messagesCount++;
      }
      NSUInteger messagesCountToInsert = MIN((limit - messages.count),messagesBatch.count);
      NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                             NSMakeRange(messagesBatch.count - messagesCountToInsert,
                                         messagesCountToInsert)];
      [messages insertObjects:[messagesBatch.array objectsAtIndexes:indexes]
                    atIndexes:[NSIndexSet indexSetWithIndexesInRange:
                               NSMakeRange(0, messagesCountToInsert)]];
      if(messagesCount >= limit)
        break;
    }
  }
  return messages;
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
  [fm createDirectoryAtPath:self.directoryPath withIntermediateDirectories:YES
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

- (NSString*)directoryPath
{
  if(!directoryPath_)
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
    directoryPath_ = [filePath stringByAppendingPathComponent:bareJid];
  }
  return directoryPath_;
}

- (NSString*)path
{
  if(!path_ || !self.dateForPath || ![self.dateForPath mv_isSameDay:[NSDate date]])
  {
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",
                          [self.dateFormatter stringFromDate:[NSDate date]],
                          kMVHistoryFileExtension];
    path_ = [self.directoryPath stringByAppendingPathComponent:fileName];
    self.dateForPath = [NSDate date];
  }
  return path_;
}

@end
