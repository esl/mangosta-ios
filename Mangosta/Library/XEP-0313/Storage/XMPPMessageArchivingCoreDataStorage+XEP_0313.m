//
//  XMPPMessageArchivingCoreDataStorage+XEP_0313.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPMessageArchivingCoreDataStorage+XEP_0313.h"

@implementation XMPPMessageArchivingCoreDataStorage (XEP_0313)

- (void)xmppOneToOneChat:(XMPPOneToOneChat *)sender didReceiveArchivedMessage:(XMPPMessage *)message
{
    XMPPJID *myJid = [self myJIDForXMPPStream:sender.xmppStream];
    BOOL isOutgoing = [[message from] isEqualToJID:myJid options:XMPPJIDCompareBare];
    
    __block BOOL isUnique;
    [self executeBlock:^{
        isUnique = [self isMessageUnique:message outgoing:isOutgoing];
    }];
    
    if (isUnique) {
        [self archiveMessage:message outgoing:isOutgoing xmppStream:sender.xmppStream];
    }
}

// TODO: XEP-0359 for more robust uniquing
- (BOOL)isMessageUnique:(XMPPMessage *)message outgoing:(BOOL)isOutgoing
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *messageEntity = [self messageEntity:moc];
    
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    
    NSDate *remoteTimestamp = [message delayedDeliveryDate];
    NSDate *minLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval:-60];
    NSDate *maxLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval: 60];
    
    NSString *messageBareJID = [(isOutgoing ? [message to] : [message from]) bare];
    NSString *streamBareJID = [(isOutgoing ? [message from] : [message to]) bare];
    
    NSPredicate *predicate =
    [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"body = %@", messageBody],
                                                         [NSPredicate predicateWithFormat:@"bareJidStr = %@", messageBareJID],
                                                         [NSPredicate predicateWithFormat:@"streamBareJidStr = %@", streamBareJID],
                                                         [NSPredicate predicateWithFormat:@"timestamp BETWEEN {%@, %@}", minLocalTimestamp, maxLocalTimestamp]
                                                         ]];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = messageEntity;
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    
    NSArray *results = [moc executeFetchRequest:fetchRequest error:NULL];
    
    return results && results.count == 0;
}

@end
