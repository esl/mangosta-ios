//
//  XMPPServiceDiscovery.m
//  Mangosta
//
//  Created by Andres Canal on 4/27/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#define XMLNS_DISCO_ITEMS  @"http://jabber.org/protocol/disco#items"
#import "XMPPServiceDiscovery.h"
#import "XMPPIDTracker.h"

@implementation XMPPServiceDiscovery

- (BOOL)activate:(XMPPStream *)aXmppStream{
	if ([super activate:aXmppStream]){
		xmppIDTracker = [[XMPPIDTracker alloc] initWithStream:xmppStream
												dispatchQueue:moduleQueue];
		return YES;
	}
	return NO;
}

- (void)fetchItemsForJID:(XMPPJID *)jid{

	// This is a public method.
	// It may be invoked on any thread/queue.
	
	dispatch_block_t block = ^{ @autoreleasepool {
		//	<iq type='get'
		//		from='romeo@montague.net/orchard'
		//		to='shakespeare.lit'
		//		id='items1'>
		//		<query xmlns='http://jabber.org/protocol/disco#items'/>
		//	</iq>
		
		NSString *iqID = [XMPPStream generateUUID];
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns: XMLNS_DISCO_ITEMS];
		XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:jid elementID:iqID child:query];

		[xmppStream sendElement:iq];
		[xmppIDTracker addID:iqID
					   target:self
					 selector:@selector(handleItemsResponse:withInfo:)
					  timeout:60.0];
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

- (void)handleItemsResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info{
	NSLog(@"%@",info);
}

@end
