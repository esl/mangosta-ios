//
//  XMPPMessageAndMAMArchivingCoreDataStorage.m
//  Mangosta
//
//  Created by Andres Canal on 5/17/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPMessageAndMAMArchivingCoreDataStorage.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"
#import "XMPPLogging.h"

@implementation XMPPMessageAndMAMArchivingCoreDataStorage{
	NSString *messageEntityName;
	NSString *contactEntityName;
}

- (void)commonInit
{
	[super commonInit];
	
	messageEntityName = @"XMPPMessageArchiving_Message_CoreDataObject";
	contactEntityName = @"XMPPMessageArchiving_Contact_CoreDataObject";
}

- (void)archiveMAMMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)xmppStream {
	// Message should either have a body, or be a composing notification

	[self scheduleBlock:^{
		NSDate *remoteTimestamp = [message delayedDeliveryDate];
		if (!remoteTimestamp){
			return;
		}

		NSManagedObjectContext *moc = [self managedObjectContext];
		NSEntityDescription *messageEntity = [self messageEntity:moc];
		NSString *messageBody = [[message elementForName:@"body"] stringValue];
		
		NSDate *minLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval:-60];
		NSDate *maxLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval: 60];
		
		XMPPJID *myJid = [self myJIDForXMPPStream:xmppStream];
		XMPPJID *messageJid = isOutgoing ? [message to] : [message from];
		
		NSString *predicateFrmt = @"body == %@ AND bareJidStr == %@ AND outgoing == %@ AND streamBareJidStr == %@ "
									@"AND "
									@"("
									@"timestamp == %@ "
									@"OR timestamp BETWEEN {%@, %@}"
									@")";
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFrmt,
								  messageBody,
								  [messageJid bare], @(isOutgoing),
								  [myJid bare],
								  remoteTimestamp,
								  minLocalTimestamp,
								  maxLocalTimestamp];
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.entity = messageEntity;
		fetchRequest.predicate = predicate;
		fetchRequest.sortDescriptors = @[sortDescriptor];
		fetchRequest.fetchLimit = 1;
		
		NSError *error = nil;
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
		
		if(error == nil & results.count == 0) {
			XMPPMessageArchiving_Message_CoreDataObject *archivedMessage = (XMPPMessageArchiving_Message_CoreDataObject *)
			[[NSManagedObject alloc] initWithEntity:[self messageEntity:moc]
					 insertIntoManagedObjectContext:nil];
			archivedMessage.message = message;
			archivedMessage.body = messageBody;
			
			archivedMessage.bareJid = [messageJid bareJID];
			archivedMessage.streamBareJidStr = [myJid bare];
			archivedMessage.timestamp = [message delayedDeliveryDate];
			archivedMessage.thread = [[message elementForName:@"thread"] stringValue];
			archivedMessage.isOutgoing = isOutgoing;
			archivedMessage.isComposing = false;
			[moc insertObject:archivedMessage];
		}
	}];
}

- (NSEntityDescription *)messageEntity:(NSManagedObjectContext *)moc
{
	// This method should be thread-safe.
	// So be sure to access the entity name through the property accessor.
	
	return [NSEntityDescription entityForName:[self messageEntityName] inManagedObjectContext:moc];
}

- (NSEntityDescription *)contactEntity:(NSManagedObjectContext *)moc
{
	// This is a public method, and may be invoked on any queue.
	// So be sure to go through the public accessor for the entity name.
	
	return [NSEntityDescription entityForName:[self contactEntityName] inManagedObjectContext:moc];
}

- (NSString *)contactEntityName
{
	__block NSString *result = nil;
	
	dispatch_block_t block = ^{
		result = contactEntityName;
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
	
	return result;
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
	return @"XMPPMessageArchiving";
}

- (NSBundle *)managedObjectModelBundle
{
	return [NSBundle bundleForClass:[XMPPMessageArchiving class]];
}

@end
