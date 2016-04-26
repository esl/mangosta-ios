//
//  XMPPMUCLight.m
//  Mangosta
//
//  Created by Andres Canal on 4/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//
#import "XMPPMessage+XEP0045.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPIDTracker.h"
#import "XMPPMUCLight.h"

@implementation XMPPMUCLight

- (void)setMyRoomJID:(XMPPJID*)userJID{
	myRoomJID = userJID;
}

- (void)setRoomSubject:(NSString*)subject{
	roomSubject = subject;
}

- (void)leaveMUCLightRoom:(XMPPJID *)userJID{
	
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
		[item addAttributeWithName:@"affiliation" stringValue:@"none"];
		[item addAttributeWithName:@"jid" stringValue:userJID.full];
		
		[query addChild:item];
		[iq addChild:query];
		
		[xmppStream sendElement:iq];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)handleLeaveMUCLightRoomResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info{
	
	if ([[iq type] isEqualToString:@"result"]){
		[multicastDelegate xmppRoom:self didLeaveMUCLightRoom:iq];
	}else{
		[multicastDelegate xmppRoom:self didNotLeaveMUCLightRoom:iq];
	}
}

- (void)fetchAllMembersList
{
	dispatch_block_t block = ^{ @autoreleasepool {
		
		
		// <iq type='get'
		//       id='member3'
		//       to='coven@chat.shakespeare.lit'>
		//   <query xmlns='http://jabber.org/protocol/muc#admin'>
		//     <item affiliation='member'/>
		//   </query>
		// </iq>
		
		NSString *iqID = [XMPPStream generateUUID];
		
		NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
		[item addAttributeWithName:@"affiliation" stringValue:@"member"];
		
		NSXMLElement *ownerItem = [NSXMLElement elementWithName:@"item"];
		[ownerItem addAttributeWithName:@"affiliation" stringValue:@"owner"];
		
		NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
		[query addChild:item];
		[query addChild:ownerItem];
		
		XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:iqID child:query];
		
		[xmppStream sendElement:iq];
		[responseTracker addID:iqID
						target:self
					  selector:@selector(handleFetchMembersListResponse:withInfo:)
					   timeout:60.0];
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
	
	
}

- (void)addUsers:(NSArray *)users{
	
	//    <iq from="crone1@shakespeare.lit/desktop"
	//          id="member1"
	//          to="coven@chat.shakespeare.lit"
	//        type="set">
	//       <query xmlns="http://jabber.org/protocol/muc#admin">
	//          <item affiliation="member" jid="hag66@shakespeare.lit" />
	//       </query>
	//    </iq>
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		NSString *iqID = [XMPPStream generateUUID];
		NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
		[iq addAttributeWithName:@"id" stringValue:iqID];
		[iq addAttributeWithName:@"to" stringValue:self.roomJID.full];
		[iq addAttributeWithName:@"type" stringValue:@"set"];
		
		
		for (XMPPJID *userJID in users) {
			NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#admin"];
			NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
			[item addAttributeWithName:@"affiliation" stringValue:@"member"];
			[item addAttributeWithName:@"jid" stringValue:userJID.full];
			
			[query addChild:item];
			[iq addChild:query];
		}
		
		[xmppStream sendElement:iq];
		[responseTracker addID:iqID
						target:self
					  selector:@selector(handleSendMessageResponse:withInfo:)
					   timeout:60.0];
	}};
	
	if (dispatch_get_specific(moduleQueueTag)){
		block();
	}else{
		dispatch_async(moduleQueue, block);
	}
}

- (void)sendMessageWithBody:(NSString *)text {
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:text];
		
		NSString *messageID = [XMPPStream generateUUID];
		XMPPMessage *message = [XMPPMessage message];
		[message addAttributeWithName:@"id" stringValue:messageID];
		[message addAttributeWithName:@"to" stringValue:roomJID.full];
		[message addAttributeWithName:@"from" stringValue:xmppStream.myJID.full];
		[message addAttributeWithName:@"type" stringValue:@"groupchat"];
		
		[message addChild:body];

		[xmppStream sendElement:message];
	}};
	
	if (dispatch_get_specific(moduleQueueTag)){
		block();
	}else{
		dispatch_async(moduleQueue, block);
	}
}


- (void)handleSendMessageResponse:(XMPPMessage *)message withInfo:(id <XMPPTrackingInfo>)info{
	if(message) {
		[multicastDelegate xmppRoom:self didSendMessage:message];
	} else {
		[multicastDelegate xmppRoom:self didFailToSendMessage:message];
	}
}

- (void)handleAddUsersResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info{
	
	if ([[iq type] isEqualToString:@"result"]){
		[multicastDelegate xmppRoom:self didAddUsers:iq];
	}else{
		[multicastDelegate xmppRoom:self didNotAddUsers:iq];
	}
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
	NSString *messageID = [message attributeForName:@"id"].stringValue;
	
	if(!messageID){
		return;
	}
	
	XMPPJID *to = [message to];
	if(![roomJID isEqualToJID:to options:XMPPJIDCompareBare]){
		return;
	}
	
	XMPPJID *userJID = message.from;
	XMPPJID *from = [XMPPJID jidWithString:self.roomJID.full resource: userJID.bare];
	
	[message addAttributeWithName:@"from" stringValue:from.full];
	[message addAttributeWithName:@"to" stringValue:userJID.bare];
	
	[xmppRoomStorage handleIncomingMessage:message room:self];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	// This method is invoked on the moduleQueue.
	
	XMPPJID *from = [message from];
	
	if (![roomJID isEqualToJID:from options:XMPPJIDCompareBare])
	{
		return; // Stanza isn't for our room
	}
	
	// Is this a message we need to store (a chat message)?
	//
	// A message to all recipients MUST be of type groupchat.
	// A message to an individual recipient would have a <body/>.
	
	BOOL isChatMessage;
	
	if ([from isFull])
		isChatMessage = [message isGroupChatMessageWithBody];
	else
		isChatMessage = [message isMessageWithBody];
	
	if (isChatMessage)
	{
		[xmppRoomStorage handleIncomingMessage:message room:self];
		[multicastDelegate xmppRoom:self didReceiveMessage:message fromOccupant:from];
	}
	else if ([message isGroupChatMessageWithSubject])
	{
		roomSubject = [message subject];
	}
	else
	{
		// Todo... Handle other types of messages.
	}
}

- (BOOL)isMAMMessage:(XMPPMessage *)message {
	DDXMLElement *resultElement = [message elementForName:@"result" xmlns:@"urn:xmpp:mam:tmp"];
	if (resultElement) {
		return YES;
	}
	return NO;
}

- (XMPPMessage *)messageForMAMMessage:(XMPPMessage *)mamMessage {
	DDXMLElement *resultElement = [mamMessage elementForName:@"result" xmlns:@"urn:xmpp:mam:tmp"];
	if (resultElement) {
		NSString *resultID = [resultElement attributeStringValueForName:@"id"];
		DDXMLElement *forwardElement = [resultElement elementForName:@"forwarded"];
		DDXMLElement *delayElement = [forwardElement elementForName:@"delay"];
		DDXMLElement *innerMessage = [forwardElement elementForName:@"message"];
		if (delayElement && innerMessage) {
			[innerMessage addChild:delayElement.copy];
			[innerMessage addAttributeWithName:@"resultId" stringValue:resultID];
			return [XMPPMessage messageFromElement:innerMessage];
		}
	}
	return nil;
}

@end
