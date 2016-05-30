//
//  XMPPMUCLight.m
//  Mangosta
//
//  Created by Andres on 5/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPMUC.h"
#import "XMPPFramework.h"
#import "XMPPLogging.h"
#import "XMPPIDTracker.h"
#import "XMPPMUCLight.h"

NSString *const XMPPDiscoverItemsNamespace = @"http://jabber.org/protocol/disco#items";
NSString *const XMPPMUCErrorDomain = @"XMPPMUCErrorDomain";

@implementation XMPPMUCLight

- (instancetype)init
{
	self = [self initWithDispatchQueue:nil];
	if (self) {

	}
	return self;
}

- (id)initWithDispatchQueue:(dispatch_queue_t)queue
{
	if ((self = [super initWithDispatchQueue:queue])) {
		rooms = [[NSMutableSet alloc] init];
	}
	return self;
}


- (BOOL)activate:(XMPPStream *)aXmppStream
{
	if ([super activate:aXmppStream])
	{
		xmppIDTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		return YES;
	}
	
	return NO;
}

- (void)deactivate
{
	dispatch_block_t block = ^{ @autoreleasepool {
		[xmppIDTracker removeAllIDs];
		xmppIDTracker = nil;
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	[super deactivate];
}

- (BOOL)discoverRoomsForServiceNamed:(NSString *)serviceName {
	
	if (serviceName.length < 2)
		return NO;
	
	dispatch_block_t block = ^{ @autoreleasepool {

		NSXMLElement *query = [NSXMLElement elementWithName:@"query"
													  xmlns:XMPPDiscoverItemsNamespace];
		XMPPIQ *iq = [XMPPIQ iqWithType:@"get"
									 to:[XMPPJID jidWithString:serviceName]
							  elementID:[xmppStream generateUUID]
								  child:query];
		
		[xmppIDTracker addElement:iq
						   target:self
						 selector:@selector(handleDiscoverRoomsQueryIQ:withInfo:)
						  timeout:60];
		
		[xmppStream sendElement:iq];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
	
	return YES;
}

- (void)handleDiscoverRoomsQueryIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)info
{
	dispatch_block_t block = ^{ @autoreleasepool {
		NSXMLElement *errorElem = [iq elementForName:@"error"];
		NSString *serviceName = [iq attributeStringValueForName:@"from" withDefaultValue:@""];
		
		if (errorElem) {
			NSString *errMsg = [errorElem.children componentsJoinedByString:@", "];
			NSInteger errorCode = [errorElem attributeIntegerValueForName:@"code" withDefaultValue:0];
			NSDictionary *dict = @{NSLocalizedDescriptionKey : errMsg};
			NSError *error = [NSError errorWithDomain:XMPPMUCErrorDomain
												 code:errorCode
											 userInfo:dict];
			
			[multicastDelegate xmppMUCLight:self failedToDiscoverRoomsForServiceNamed:serviceName withError:error];
			return;
		}
		
		NSXMLElement *query = [iq elementForName:@"query"
										   xmlns:XMPPDiscoverItemsNamespace];
		
		NSArray *items = [query elementsForName:@"item"];

		[multicastDelegate xmppMUCLight:self didDiscoverRooms:items forServiceNamed:serviceName];
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	NSString *type = [iq type];
	
	if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"])
	{
		return [xmppIDTracker invokeForID:[iq elementID] withObject:iq];
	}
	
	return NO;
}


@end
