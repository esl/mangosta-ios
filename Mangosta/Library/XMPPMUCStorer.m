//
//  XMPPMUCStorer.m
//  Mangosta
//
//  Created by Andres Canal on 5/3/16.
//  Copyright © 2016 Inaka. All rights reserved.
//
#import "XMPPMUCStorer.h"
#import "XMPPMessage+XEP0045.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessage+XEP_0313.h"
#import "XMPP.h"


@implementation XMPPMUCStorer

- (id)initWithRoomStorage:(XMPPMUCCoreDataStorage *)storage
{
	if ((self = [super initWithDispatchQueue:nil]))
	{
		_xmppMUCStorage = storage;
	}
	return self;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	XMPPMessage *messageToStore = message;
	
	if([message isMessageArchive]){		
		[self.xmppMUCStorage handleMAMMessage:message stream:self.xmppStream];
		return;
	}
	
	if(!([messageToStore isGroupChatMessageWithBody] && [messageToStore.from isFull])){
		return;
	}
	
	XMPPJID *myRoomJID = [XMPPJID jidWithString: messageToStore.from.bare];
	XMPPJID *messageJID = messageToStore.from;
	
	if ([myRoomJID isEqualToJID:messageJID])
	{
		if (![messageToStore wasDelayed])
		{
			// Ignore - we already stored message in handleOutgoingMessage:room:
			return;
		}
	}
	
	[self.xmppMUCStorage handleIncomingMessage:messageToStore stream:self.xmppStream];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
	if(!([message isGroupChatMessageWithBody] && message.from == nil)){
		return;
	}

	[self.xmppMUCStorage handleOutgoingMessage:message stream:self.xmppStream];
}

@end
