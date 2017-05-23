//
//  XMPPRoomLightCoreDataStorage+XEP_0313.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRoomLightCoreDataStorage+XEP_0313.h"

@interface XMPPRoomLightCoreDataStorage (Protected)

- (NSEntityDescription *)messageEntity:(NSManagedObjectContext *)moc;

- (void)insertMessage:(XMPPMessage *)message
             outgoing:(BOOL)isOutgoing
              forRoom:(XMPPRoomLight *)room
               stream:(XMPPStream *)xmppStream;

@end

@implementation XMPPRoomLightCoreDataStorage (XEP_0313)

- (void)importRemoteArchiveMessage:(XMPPMessage *)message room:(XMPPRoomLight *)room fromStream:(XMPPStream *)stream
{
    XMPPJID *sender = [XMPPJID jidWithString:[message from].resource];
    XMPPJID *me = [self myJIDForXMPPStream:stream];
    BOOL isOutgoing = [sender isEqualToJID:me options:XMPPJIDCompareBare];
    
    [self scheduleBlock:^{
        if ([self isMessageUnique:message inRoom:room]) {
            [self insertMessage:message outgoing:isOutgoing forRoom:room stream:stream];
        }
    }];
}

// TODO: XEP-0359 for more robust uniquing
- (BOOL)isMessageUnique:(XMPPMessage *)message inRoom:(XMPPRoomLight *)room
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *messageEntity = [self messageEntity:moc];
    
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    
    NSString *senderFullJID = [[message from] full];
    
    NSDate *remoteTimestamp = [message delayedDeliveryDate];
    NSDate *minLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval:-60];
    NSDate *maxLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval: 60];
    
    NSPredicate *predicate =
    [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"body = %@", messageBody],
                                                         [NSPredicate predicateWithFormat:@"jidStr = %@", senderFullJID],
                                                         [NSCompoundPredicate orPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"remoteTimestamp = %@", remoteTimestamp],
                                                                                                             [NSPredicate predicateWithFormat:@"localTimestamp BETWEEN {%@, %@}", minLocalTimestamp, maxLocalTimestamp]
                                                                                                             ]],
                                                         ]];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = messageEntity;
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    
    NSArray *results = [moc executeFetchRequest:fetchRequest error:NULL];
    
    return results && results.count == 0;
}

@end
