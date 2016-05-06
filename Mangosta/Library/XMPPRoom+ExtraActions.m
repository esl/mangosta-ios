//
//  XMPPRoom+ExtraActions.m
//  Mangosta
//
//  Created by Andres Canal on 5/6/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPRoom+ExtraActions.h"


@implementation XMPPRoom (ExtraActions)

- (void)changeAffiliation:(XMPPJID *)userJID affiliation:(NSString *) affiliation {
	
	//		<iq from='crone1@shakespeare.lit/desktop'
	//				id='member2'
	//				to='coven@chat.shakespeare.lit'
	//				type='set'>
	//			<query xmlns='http://jabber.org/protocol/muc#admin'>
	//				<item affiliation='none' jid='hag66@shakespeare.lit'/>
	//			</query>
	//		</iq>
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		NSString *iqID = [XMPPStream generateUUID];
		NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
		[iq addAttributeWithName:@"id" stringValue:iqID];
		[iq addAttributeWithName:@"to" stringValue:self.roomJID.full];
		[iq addAttributeWithName:@"type" stringValue:@"set"];
		
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#admin"];
		NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
		[item addAttributeWithName:@"affiliation" stringValue:affiliation];
		[item addAttributeWithName:@"jid" stringValue:userJID.full];
		
		[query addChild:item];
		[iq addChild:query];
		
		[xmppStream sendElement:iq];
		
		[responseTracker addID:iqID
						target:self
					  selector:@selector(handleAffiliationResponseResponse:withInfo:)
					   timeout:60.0];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)handleAffiliationResponseResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info {
	if ([[iq type] isEqualToString:@"result"]){
		[multicastDelegate xmppRoom:self didChangeAffiliationTo:iq.to.bareJID];
	}else{
		[multicastDelegate xmppRoom:self didFailToChangeAffiliationTo:iq.to.bareJID];
	}
}


@end
