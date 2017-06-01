//
//  XMPPServiceDiscovery.m
//  Mangosta
//
//  Created by Andres Canal on 4/27/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#define XMLNS_DISCO_ITEMS  @"http://jabber.org/protocol/disco#items"
#define XMLNS_DISCO_INFO @"http://jabber.org/protocol/disco#info"
#import "XMPPServiceDiscovery.h"
#import "XMPPIDTracker.h"

@interface XMPPServiceDiscovery()
	@property BOOL discoveringInfo;
@end

@implementation XMPPServiceDiscovery

- (BOOL)activate:(XMPPStream *)aXmppStream {
	
	if ([super activate:aXmppStream]) {
		xmppIDTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		
		return YES;
	}
	
	return NO;
}

- (void)deactivate {
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

- (void) discoInfoOrItem:(NSString *) infoOrItems jid:(XMPPJID *) jid {
	
	dispatch_block_t block = ^{ @autoreleasepool {
		//	<iq type='get'
		//		from='romeo@montague.net/orchard'
		//		to='shakespeare.lit'
		//		id='items1'>
		//		<query xmlns='http://jabber.org/protocol/disco#items'/> // disco#info
		//	</iq>
		
		NSString *iqID = [XMPPStream generateUUID];
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns: infoOrItems];
		XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:jid elementID:iqID child:query];
		
		[xmppIDTracker addID:iqID
					  target:self
					selector:@selector(handleDiscovery:withInfo:)
					 timeout:60.0];
		
		[xmppStream sendElement:iq];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)discoverInformationAbout:(XMPPJID *)jid{
	self.discoveringInfo = true;
	[self discoInfoOrItem:XMLNS_DISCO_INFO jid:jid];
}


- (void)discoverItemsAssociatedWith:(XMPPJID *)jid{
	self.discoveringInfo = false;
	[self discoInfoOrItem:XMLNS_DISCO_ITEMS jid:jid];
}

- (void)handleDiscovery:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info{

	if ([[iq type] isEqualToString:@"result"]){
		NSXMLElement *query = [iq elementForName:@"query"];
		NSArray *items = [query children];
		
		if (self.discoveringInfo) {
			[multicastDelegate xmppServiceDiscovery:self didDiscoverInformation:items];
		} else {
			[multicastDelegate xmppServiceDiscovery:self didDiscoverItems:items];
		}

	} else {
		[multicastDelegate xmppServiceDiscovery:self didFailToDiscover:iq];
	}
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
