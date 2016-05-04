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
	// This method is invoked on the moduleQueue.

	NSLog(@"%@",message);
	
	if(!([message isGroupChatMessage] && [message.from isFull])){
		return;
	}
	
	XMPPJID *myRoomJID = [XMPPJID jidWithString: message.from.bare];
	XMPPJID *messageJID = message.from;
	
	if ([myRoomJID isEqualToJID:messageJID])
	{
		if (![message wasDelayed])
		{
			// Ignore - we already stored message in handleOutgoingMessage:room:
			return;
		}
	}
	
	[self.xmppMUCStorage handleIncomingMessage:message stream:self.xmppStream];
}



@end
