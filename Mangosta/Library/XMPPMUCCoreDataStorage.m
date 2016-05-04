//
//  XMPPMUCCoreDataStorage.m
//  Mangosta
//
//  Created by Andres Canal on 5/4/16.
//  Copyright © 2016 Inaka. All rights reserved.
//
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMUCCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"
#import "XMPPRoomMessageCoreDataStorageObject.h"
#import "XMPPRoomOccupantCoreDataStorageObject.h"

@implementation XMPPMUCCoreDataStorage {
	NSString *messageEntityName;
	NSString *occupantEntityName;
	
	NSTimeInterval maxMessageAge;
	NSTimeInterval deleteInterval;
}

static XMPPMUCCoreDataStorage *sharedInstance;

- (void)commonInit
{
	[super commonInit];

	// This method is invoked by all public init methods of the superclass

	messageEntityName = NSStringFromClass([XMPPRoomMessageCoreDataStorageObject class]);
	occupantEntityName = NSStringFromClass([XMPPRoomOccupantCoreDataStorageObject class]);
	
	maxMessageAge  = (60 * 60 * 24 * 7); // 7 days
	deleteInterval = (60 * 5);           // 5 days

}

- (void)dealloc
{

}

- (void)handleIncomingMessage:(XMPPMessage *)message stream:(XMPPStream *) stream
{
	[self scheduleBlock:^{
		if(![self existsMessage:message stream:stream]) {
			NSLog(@"CHUCHA CUCHA");
		}
	}];
}

- (BOOL)existsMessage:(XMPPMessage *)message stream:(XMPPStream *)xmppStream
{
	NSDate *remoteTimestamp = [message delayedDeliveryDate];
	
	if (remoteTimestamp == nil)
	{
		// When the xmpp server sends us a room message, it will always timestamp delayed messages.
		// For example, when retrieving the discussion history, all messages will include the original timestamp.
		// If a message doesn't include such timestamp, then we know we're getting it in "real time".
		
		return NO;
	}
	
	// Does this message already exist in the database?
	// How can we tell if two XMPPRoomMessages are the same?
	//
	// 1. Same streamBareJidStr
	// 2. Same jid
	// 3. Same text
	// 4. Approximately the same timestamps
	//
	// This is actually a rather difficult question.
	// What if the same user sends the exact same message multiple times?
	//
	// If we first received the message while already in the room, it won't contain a remoteTimestamp.
	// Returning to the room later and downloading the discussion history will return the same message,
	// this time with a remote timestamp.
	//
	// So if the message doesn't have a remoteTimestamp,
	// but it's localTimestamp is approximately the same as the remoteTimestamp,
	// then this is enough evidence to consider the messages the same.
	//
	// Note: Predicate order matters. Most unique key should be first, least unique should be last.
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEntityDescription *messageEntity = [self messageEntity:moc];
	
	NSString *streamBareJidStr = [[self myJIDForXMPPStream:xmppStream] bare];
	
	XMPPJID *messageJID = [message from];
	NSString *messageBody = [[message elementForName:@"body"] stringValue];
	
	NSDate *minLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval:-60];
	NSDate *maxLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval: 60];
	
	NSString *predicateFormat = @"    body == %@ "
	@"AND jidStr == %@ "
	@"AND streamBareJidStr == %@ "
	@"AND "
	@"("
	@"     (remoteTimestamp == %@) "
	@"  OR (remoteTimestamp == NIL && localTimestamp BETWEEN {%@, %@})"
	@")";
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat,
							  messageBody, messageJID, streamBareJidStr,
							  remoteTimestamp, minLocalTimestamp, maxLocalTimestamp];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:messageEntity];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
	
	if (error)
	{
		NSLog(@"%@",error);
	}
	
	return ([results count] > 0);
}

- (NSEntityDescription *)messageEntity:(NSManagedObjectContext *)moc
{
	// This method should be thread-safe.
	// So be sure to access the entity name through the property accessor.
	
	return [NSEntityDescription entityForName:[self messageEntityName] inManagedObjectContext:moc];
}

- (NSString *)messageEntityName
{
	__block NSString *result = nil;
	
	dispatch_block_t block = ^{
		result = messageEntityName;
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
	
	return result;
}

- (NSString *)managedObjectModelName
{
	return @"XMPPRoom";
}

@end
