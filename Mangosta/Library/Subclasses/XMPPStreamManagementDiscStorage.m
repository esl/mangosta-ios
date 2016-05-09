//
//  XMPPStreamManagementDiscStorage.m
//  Mangosta
//
//  Created by Andres on 5/9/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPStreamManagementDiscStorage.h"
#import "XMPPFramework/XMPPStreamManagementStanzas.h"

#define XMPPStreamManagementDiscStorageName @"XMPPStreamManagementDiscStorageName"

#pragma mark -

@implementation XMPPStreamManagementDiscStorage
{
	int32_t isConfigured;
	
	NSString *resumptionId;
	uint32_t timeout;
	
	NSDate *lastDisconnect;
	uint32_t lastHandledByClient;
	uint32_t lastHandledByServer;
	NSArray *pendingOutgoingStanzas;
	
	void *storageQueueTag;
	dispatch_queue_t storageQueue;
}

- (BOOL)configureWithParent:(XMPPStreamManagement *)parent queue:(dispatch_queue_t)queue
{
	const char *moduleQueueName = [NSStringFromClass([self class]) UTF8String];
	storageQueue = dispatch_queue_create(moduleQueueName, NULL);
	
	storageQueueTag = &storageQueueTag;
	dispatch_queue_set_specific(storageQueue, storageQueueTag, storageQueueTag, NULL);
	
	return true;
}

/**
 * Invoked after we receive <enabled/> from the server.
 *
 * @param resumptionId
 *   The ID required to resume the session, given to us by the server.
 *
 * @param timeout
 *   The timeout in seconds.
 *   After a disconnect, the server will maintain our state for this long.
 *   If we attempt to resume the session after this timeout it likely won't work.
 *
 * @param lastDisconnect
 *   Used to reset the lastDisconnect value.
 *   This value is often updated during the session, to ensure it closely resemble the date the server will use.
 *   That is, if the client application is killed (or crashes) we want a relatively accurate lastDisconnect date.
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 *
 * This method should also nil out the following values (if needed) associated with the account:
 * - lastHandledByClient
 * - lastHandledByServer
 * - pendingOutgoingStanzas
 **/
- (void)setResumptionId:(NSString *)inResumptionId
				timeout:(uint32_t)inTimeout
		 lastDisconnect:(NSDate *)inLastDisconnect
			  forStream:(XMPPStream *)stream
{
	dispatch_block_t block = ^{
		resumptionId = inResumptionId;
		timeout = inTimeout;
		lastDisconnect = inLastDisconnect;
		
		lastHandledByClient = 0;
		lastHandledByServer = 0;
		pendingOutgoingStanzas = nil;

		[self saveState];
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
}

/**
 * This method is invoked ** often ** during stream operation.
 * It is not invoked when the xmppStream is disconnected.
 *
 * Important: See the note [in XMPPStreamManagement.h]: "Optimizing storage demands during active stream usage"
 *
 * @param date
 *   Updates the previous lastDisconnect value.
 *
 * @param lastHandledByClient
 *   The most recent 'h' value we can safely send to the server.
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)inLastDisconnect
	  lastHandledByClient:(uint32_t)inLastHandledByClient
				forStream:(XMPPStream *)stream
{
	
	dispatch_block_t block = ^{
		lastDisconnect = inLastDisconnect;
		lastHandledByClient = inLastHandledByClient;

		[self saveState];
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
}

/**
 * This method is invoked ** often ** during stream operation.
 * It is not invoked when the xmppStream is disconnected.
 *
 * Important: See the note [in XMPPStreamManagement.h]: "Optimizing storage demands during active stream usage"
 *
 * @param date
 *   Updates the previous lastDisconnect value.
 *
 * @param lastHandledByServer
 *   The most recent 'h' value we've received from the server.
 *
 * @param pendingOutgoingStanzas
 *   An array of XMPPStreamManagementOutgoingStanza objects.
 *   The storage layer is in charge of properly persisting this array, including:
 *   - the array count
 *   - the stanzaId of each element, including those that are nil
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)inLastDisconnect
	  lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
				forStream:(XMPPStream *)stream
{

	dispatch_block_t block = ^{
		lastDisconnect = inLastDisconnect;
		lastHandledByServer = inLastHandledByServer;
		pendingOutgoingStanzas = inPendingOutgoingStanzas;
		
		[self saveState];
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
}

/**
 * This method is invoked immediately after an accidental disconnect.
 * And may be invoked post-disconnect if the state changes, such as for the following edge cases:
 *
 * - due to continued processing of stanzas received pre-disconnect,
 *   that are just now being marked as handled by the delegate(s)
 * - due to a delayed response from the delegate(s),
 *   such that we didn't receive the stanzaId for an outgoing stanza until after the disconnect occurred.
 *
 * This method is not invoked if stream management is started on a connected xmppStream.
 *
 * @param date
 *   This value will be the actual disconnect date.
 *
 * @param lastHandledByClient
 *   The most recent 'h' value we can safely send to the server.
 *
 * @param lastHandledByServer
 *   The most recent 'h' value we've received from the server.
 *
 * @param pendingOutgoingStanzas
 *   An array of XMPPStreamManagementOutgoingStanza objects.
 *   The storage layer is in charge of properly persisting this array, including:
 *   - the array count
 *   - the stanzaId of each element, including those that are nil
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)inLastDisconnect
	  lastHandledByClient:(uint32_t)inLastHandledByClient
	  lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
				forStream:(XMPPStream *)stream
{
	dispatch_block_t block = ^{
		lastDisconnect = inLastDisconnect;
		lastHandledByClient = inLastHandledByClient;
		lastHandledByServer = inLastHandledByServer;
		pendingOutgoingStanzas = inPendingOutgoingStanzas;
		
		[self saveState];
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
}

/**
 * Invoked when the extension needs values from a previous session.
 * This method is used to get values needed in order to determine if it can resume a previous stream.
 **/
- (void)getResumptionId:(NSString **)resumptionIdPtr
				timeout:(uint32_t *)timeoutPtr
		 lastDisconnect:(NSDate **)lastDisconnectPtr
			  forStream:(XMPPStream *)stream
{
	[self loadState];
	
	if (resumptionIdPtr)   *resumptionIdPtr   = resumptionId;
	if (timeoutPtr)        *timeoutPtr        = timeout;
	if (lastDisconnectPtr) *lastDisconnectPtr = lastDisconnect;
}

/**
 * Invoked when the extension needs values from a previous session.
 * This method is used to get values needed in order to resume a previous stream.
 **/
- (void)getLastHandledByClient:(uint32_t *)lastHandledByClientPtr
		   lastHandledByServer:(uint32_t *)lastHandledByServerPtr
		pendingOutgoingStanzas:(NSArray **)pendingOutgoingStanzasPtr
					 forStream:(XMPPStream *)stream;
{
	[self loadState];
	
	if (lastHandledByClientPtr)    *lastHandledByClientPtr    = lastHandledByClient;
	if (lastHandledByServerPtr)    *lastHandledByServerPtr    = lastHandledByServer;
	if (pendingOutgoingStanzasPtr) *pendingOutgoingStanzasPtr = pendingOutgoingStanzas;
}

/**
 * Instructs the storage layer to remove all values stored for the given stream.
 * This occurs after the extension detects a "cleanly closed stream",
 * in which case the stream cannot be resumed next time.
 **/
- (void)removeAllForStream:(XMPPStream *)stream
{
	dispatch_block_t block = ^{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:XMPPStreamManagementDiscStorageName];
	};
	
	if (dispatch_get_specific(storageQueueTag))
		block();
	else
		dispatch_sync(storageQueue, block);
}

- (void)saveState {
	NSMutableDictionary *payload = [NSMutableDictionary dictionary];
	
	[payload setObject:resumptionId forKey:@"resumptionId"];
	[payload setObject:@(timeout) forKey:@"timeout"];
	[payload setObject:@(lastHandledByClient) forKey:@"lastHandledByClient"];
	[payload setObject:@(lastHandledByServer) forKey:@"lastHandledByServer"];
	if (lastDisconnect) {
		[payload setObject:lastDisconnect forKey:@"lastDisconnect"];
	}
	
	NSMutableArray *mary = [NSMutableArray array];
	for (XMPPStreamManagementOutgoingStanza *obj in pendingOutgoingStanzas) {
		[mary addObject:[NSKeyedArchiver archivedDataWithRootObject:obj]];
	}
	[payload setObject:mary forKey:@"pendingOutgoingStanzas"];
	
	[[NSUserDefaults standardUserDefaults] setObject:payload forKey:XMPPStreamManagementDiscStorageName];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadState {
	NSDictionary *payload = [[NSUserDefaults standardUserDefaults] objectForKey:XMPPStreamManagementDiscStorageName];
	
	NSMutableArray *objectStanzas = [NSMutableArray array];
	
	if ([payload objectForKey:@"pendingOutgoingStanzas"]) {
		NSArray *stanzas = [payload objectForKey:@"pendingOutgoingStanzas"];
		for (NSData *data in stanzas) {
			XMPPStreamManagementOutgoingStanza *stanza = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			[objectStanzas addObject:stanza];
		}
	}
	
	resumptionId = payload[@"resumptionId"];
	timeout = [payload[@"timeout"] unsignedIntValue];
	lastDisconnect = payload[@"lastDisconnect"];
	
	lastHandledByClient = 0;
	lastHandledByServer = 0;
	pendingOutgoingStanzas = objectStanzas;
}

@end
