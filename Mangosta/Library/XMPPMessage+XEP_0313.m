//
//  XMPPMessage+XEP_0313.m
//  Mangosta
//
//  Created by Tom Ryan on 4/8/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPMessage+XEP_0313.h"
#import "XMPPJID.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"

#define XMLNS_XMPP_MAM @"ur:xmpp:mam:tmp"

@implementation XMPPMessage (XEP_0313)

- (NSXMLElement *)receivedMessageArchiveResult {
	return [self elementForName:@"forwarded" xmlns:XMLNS_XMPP_MAM];
}

- (BOOL)isMessageArchive {
	if ([self receivedMessageArchiveResult]) {
		return YES;
	}
	return NO;
}

- (XMPPMessage *)messageForForwardedArchiveMessage {
	DDXMLElement *internalMessage = [self elementForName:@"message"];
	DDXMLElement *delay = [self elementForName:@"delay"];
	NSString *resultId = [self attributeStringValueForName:@"id"];
	
	XMPPMessage *message = [XMPPMessage messageFromElement:internalMessage];
	if (delay) {
		[message addChild:delay];
	}
	if (resultId) {
		[message addAttributeWithName:@"resultId" stringValue:resultId];
	}
	
	return message;
}

@end
