//
//  XMPPCustomRoomLight.m
//  Mangosta
//
//  Created by Andres Canal on 7/1/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPCustomRoomLight.h"
#import "XMPPFramework/XMPPMessage+XEP0045.h"
#import "XMPPMessage+XEP_0308.h"

@interface XMPPRoomLight() 
	
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message;
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message;

@end


@implementation XMPPCustomRoomLight

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
	
	XMPPMessage *messageToForwardToSuperClass = message;
	NSXMLElement *forwarded = [[message elementForName:@"result"] elementForName:@"forwarded"];
	if(forwarded){
		NSXMLElement *historyMessageElement = [forwarded elementForName:@"message"];
		messageToForwardToSuperClass = [XMPPMessage messageFromElement:historyMessageElement];
	}
	
	if ([message isMessageCorrection]){
		NSLog(@"received message correction22 message is %@",message );
		NSLog(@"TODO: fetch the ID and replace this entry");
	}
	
	XMPPJID *from = [messageToForwardToSuperClass from];
	if (![self.roomJID isEqualToJID:from options:XMPPJIDCompareBare]){
		return; // Stanza isn't for our room
	}

	if (!([messageToForwardToSuperClass.from isFull] && [messageToForwardToSuperClass isGroupChatMessageWithBody])) {
		return; //message is not a message with body
	} else if([messageToForwardToSuperClass.from.resource isEqualToString:self.xmppStream.myJID.bare] && [messageToForwardToSuperClass elementForName:@"delay"]){
		NSXMLElement *delayFromOriginal = [messageToForwardToSuperClass elementForName:@"delay"];
		
		NSXMLElement *mockMessage = [NSXMLElement elementWithName:@"message" xmlns:@"jabber:client"];
		[mockMessage addAttributeWithName:@"to" stringValue:messageToForwardToSuperClass.from.bare];
		[mockMessage addAttributeWithName:@"from" stringValue:messageToForwardToSuperClass.from.resource];
		[mockMessage addAttributeWithName:@"type" stringValue:@"groupchat"];
		[mockMessage addChild:[NSXMLElement elementWithName:@"body" stringValue:messageToForwardToSuperClass.body]];
		
		NSXMLElement *delayElement = [NSXMLElement elementWithName:@"delay" xmlns:@"urn:xmpp:delay"];
		[delayElement addAttributeWithName:@"stamp" stringValue:[delayFromOriginal attributeStringValueForName:@"stamp"]];
		[mockMessage addChild:delayElement];
		
		XMPPMessage *sentMessage = [XMPPMessage messageFromElement:mockMessage];
		[super xmppStream:sender didSendMessage:sentMessage];
		return;
	}

	[super xmppStream:sender didReceiveMessage:messageToForwardToSuperClass];
}

@end
