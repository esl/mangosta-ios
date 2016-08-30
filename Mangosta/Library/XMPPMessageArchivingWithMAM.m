//
//  XMPPMessageArchivingWithMAM.m
//  Mangosta
//
//  Created by Andres on 5/16/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPMessageArchivingWithMAM.h"
#import "XMPPMessage+XEP_0313.h"
#import "XMPPMessage+XEP0045.h"
#import "XMPPMessageAndMAMArchivingCoreDataStorage.h"
#import "XMPPMessage+XEP_0308.h"

@implementation XMPPMessageArchivingWithMAM

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if ([message isGroupChatMessage]) {
		return;
	}
	
	if (![message isMessageArchive] && [self shouldArchiveMessage:message outgoing:NO xmppStream:sender])
	{
		[xmppMessageArchivingStorage archiveMessage:message outgoing:NO xmppStream:sender];
	}
	
	if ([message isMessageArchive]) {
		XMPPMessage *messageFromMessage = [message messageForForwardedArchiveMessage];
		
		XMPPMessageAndMAMArchivingCoreDataStorage *storage = (XMPPMessageAndMAMArchivingCoreDataStorage *)xmppMessageArchivingStorage;
		BOOL outgoing = messageFromMessage.from.user == sender.myJID.user;
		[storage archiveMAMMessage:messageFromMessage outgoing:outgoing xmppStream:sender];
	}
	if ([message isMessageCorrection]){
		NSLog(@"is message correction");
	}
}

- (BOOL)shouldArchiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)xmppStream
{
	// XEP-0136 Section 2.9: Preferences precedence rules:
	//
	// When determining archiving preferences for a given message, the following rules shall apply:
	//
	// 1. 'save' value is taken from the <session> element that matches the conversation, if present,
	//    else from the <item> element that matches the contact (see JID Matching), if present,
	//    else from the default element.
	//
	// 2. 'otr' and 'expire' value are taken from the <item> element that matches the contact, if present,
	//    else from the default element.
	
	NSXMLElement *match = nil;
	
	NSString *messageThread = [[message elementForName:@"thread"] stringValue];
	if (messageThread)
	{
		// First priority - matching session element
		
		for (NSXMLElement *session in [self.preferences elementsForName:@"session"])
		{
			NSString *sessionThread = [session attributeStringValueForName:@"thread"];
			if ([messageThread isEqualToString:sessionThread])
			{
				match = session;
				break;
			}
		}
	}
	
	if (match == nil)
	{
		// Second priority - matching item element
		//
		//
		// XEP-0136 Section 10.1: JID Matching
		//
		// The following rules apply:
		//
		// 1. If the JID is of the form <localpart@domain.tld/resource>, only this particular JID matches.
		// 2. If the JID is of the form <localpart@domain.tld>, any resource matches.
		// 3. If the JID is of the form <domain.tld>, any node matches.
		//
		// However, having these rules only would make impossible a match like "all collections having JID
		// exactly equal to bare JID/domain JID". Therefore, when the 'exactmatch' attribute is set to "true" or
		// "1" on the <list/>, <remove/> or <item/> element, a JID value such as "example.com" matches
		// that exact JID only rather than <*@example.com>, <*@example.com/*>, or <example.com/*>, and
		// a JID value such as "localpart@example.com" matches that exact JID only rather than
		// <localpart@example.com/*>.
		
		XMPPJID *messageJid;
		if (isOutgoing)
			messageJid = [message to];
		else
			messageJid = [message from];
		
		NSXMLElement *match_full = nil;
		NSXMLElement *match_bare = nil;
		NSXMLElement *match_domain = nil;
		
		for (NSXMLElement *item in [self.preferences elementsForName:@"item"])
		{
			XMPPJID *itemJid = [XMPPJID jidWithString:[item attributeStringValueForName:@"jid"]];
			
			if (itemJid.resource)
			{
				BOOL match = [messageJid isEqualToJID:itemJid options:XMPPJIDCompareFull];
				
				if (match && (match_full == nil))
				{
					match_full = item;
				}
			}
			else if (itemJid.user)
			{
				BOOL exactmatch = [item attributeBoolValueForName:@"exactmatch" withDefaultValue:NO];
				BOOL match;
				
				if (exactmatch)
					match = [messageJid isEqualToJID:itemJid options:XMPPJIDCompareFull];
				else
					match = [messageJid isEqualToJID:itemJid options:XMPPJIDCompareBare];
				
				if (match && (match_bare == nil))
				{
					match_bare = item;
				}
			}
			else
			{
				BOOL exactmatch = [item attributeBoolValueForName:@"exactmatch" withDefaultValue:NO];
				BOOL match;
				
				if (exactmatch)
					match = [messageJid isEqualToJID:itemJid options:XMPPJIDCompareFull];
				else
					match = [messageJid isEqualToJID:itemJid options:XMPPJIDCompareDomain];
				
				if (match && (match_domain == nil))
				{
					match_domain = item;
				}
			}
		}
		
		if (match_full)
			match = match_full;
		else if (match_bare)
			match = match_bare;
		else if (match_domain)
			match = match_domain;
	}
	
	if (match == nil)
	{
		// Third priority - default element
		
		match = [self.preferences elementForName:@"default"];
	}
	
	if (match == nil)
	{
		return NO;
	}
	
	// The 'save' attribute specifies the user's default setting for Save Mode.
	// The allowable values are:
	//
	// - body    : the saving entity SHOULD save only <body/> elements.
	// - false   : the saving entity MUST save nothing.
	// - message : the saving entity SHOULD save the full XML content of each <message/> element.
	// - stream  : the saving entity SHOULD save every byte that passes over the stream in either direction.
	//
	// Note: We currently only support body, and treat values of 'message' or 'stream' the same as 'body'.
	
	NSString *save = [[match attributeStringValueForName:@"save"] lowercaseString];
	
	if ([save isEqualToString:@"false"])
		return NO;
	else
		return YES;
}

@end
