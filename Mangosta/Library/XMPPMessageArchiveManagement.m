//
//  XMPPMessageArchiveManagement.m
//  Mangosta
//
//  Created by Tom Ryan on 4/8/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPMessageArchiveManagement.h"
#import "XMPPFramework.h"
#import "XMPPLogging.h"
#import "XMPPIDTracker.h"
#import "XMPPMessage+XEP_0313.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_VERBOSE; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

#define XMLNS_XMPP_MAM @"urn:xmpp:mam:1"

@interface XMPPMessageArchiveManagement ()
@property NSInteger messageCount;
@property NSInteger currentMessageCount;
@property (nonatomic, strong) NSString *queryId;
@end

@implementation XMPPMessageArchiveManagement

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
	self = [super initWithDispatchQueue:queue];
	
	if (self) {
		self.messageCount = INT_MIN;
		self.queryId = [XMPPStream generateUUID];
	}
	
	return self;
}

- (void)retrieveMessageArchiveFrom:(XMPPJID *)userJID withPageSize:(NSInteger)pageSize {
	dispatch_block_t block = ^{
		
		if (!retrievingMessageArchive && [xmppIDTracker numberOfIDs] == 0) {
			retrievingMessageArchive = YES;
			
			XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
			[iq addAttributeWithName:@"id" stringValue:self.queryId];
			
			DDXMLElement *queryElement = [DDXMLElement elementWithName:@"query" xmlns:XMLNS_XMPP_MAM];
			[queryElement addAttributeWithName:@"queryId" stringValue:[XMPPStream generateUUID]];
			[iq addChild:queryElement];
			
			DDXMLElement *xElement = [DDXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
			[xElement addAttributeWithName:@"type" stringValue:@"submit"];
			[xElement addChild:[self fieldWithVar:@"FORM_TYPE" type:@"hidden" andValue:@"urn:xmpp:mam:1"]];
			
			[queryElement addChild:xElement];
			
			DDXMLElement *max = [DDXMLElement elementWithName:@"max"];
			max.stringValue = [NSString stringWithFormat:@"%ld",pageSize];
			
			DDXMLElement *set = [DDXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
			[set addChild:max];
			
			[queryElement addChild:set];
			
			[xmppIDTracker addElement:iq target:self selector:@selector(enableMessageArchiveIQ:withInfo:) timeout:XMPPIDTrackerTimeoutNone];
			[xmppStream sendElement:iq];
		}
	};
	
	if (dispatch_get_specific(moduleQueueTag)) {
		block();
	} else {
		dispatch_sync(moduleQueue, block);
	}
}

- (DDXMLElement *) fieldWithVar:(NSString *) var type:(NSString *) type andValue:(NSString *) value {
	DDXMLElement *field = [DDXMLElement elementWithName:@"field"];
	[field addAttributeWithName:@"var" stringValue:var];
	[field addAttributeWithName:@"type" stringValue:type];

	DDXMLElement *elementValue = [DDXMLElement elementWithName:@"value"];
	elementValue.stringValue = value;
	
	[field addChild:elementValue];
	
	return field;
}

- (BOOL)activate:(XMPPStream *)aXmppStream {
	XMPPLogTrace();
	
	if ([super activate:aXmppStream]) {
		XMPPLogVerbose(@"%@: Activated", THIS_FILE);
		xmppIDTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		
		
		return YES;
	}
	return NO;
}

- (void)deactivate {
	XMPPLogTrace();
	
	dispatch_block_t block = ^{ @autoreleasepool {
		[xmppIDTracker removeAllIDs];
		xmppIDTracker = nil;
	}};
	
	if (dispatch_get_specific(moduleQueueTag)) {
		block();
	} else {
		dispatch_sync(moduleQueue, block);
	}
	
	[super deactivate];
}

- (NSInteger)parseForCount:(XMPPIQ *)iq {
	NSInteger returnCount = INT_MIN;
	
	DDXMLElement *finElement = [iq elementForName:@"fin" xmlns:XMLNS_XMPP_MAM];
	if (finElement) {
		DDXMLElement *setElement = [finElement elementForName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
		
		if (setElement) {
			DDXMLNode *countNode = [setElement elementForName:@"count"];
			if (countNode) {
				returnCount = [[countNode stringValue] integerValue];
			}
		}
	}
	
	return returnCount;
}

- (void)resetToDefaults {
	self.queryId = nil;
	retrievingMessageArchive = NO;
	self.currentMessageCount = 0;
	self.messageCount = 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq; {
	NSString *incomingQueryId = [iq attributeStringValueForName:@"id"];
	if ([incomingQueryId isEqualToString:self.queryId]) {
		self.messageCount = [self parseForCount:iq];
		[multicastDelegate xmppMessageArchiveManagement:self didReceiveMessageCount:self.messageCount];
		return NO;
	}
	
	return YES;
}

- (void)enableMessageArchiveIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)trackerInfo {
	XMPPLogTrace();
	
	if ([iq isResultIQ]) {
		
	}
}

- (XMPPMessage *)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
	if ([message isMessageArchive]) {
		self.currentMessageCount++;
		XMPPMessage *messageArchiveForwardedMessage = [message messageForForwardedArchiveMessage];
		
		[multicastDelegate xmppMessageArchiveManagement:self didReceiveMessage:messageArchiveForwardedMessage];
		
		if (self.messageCount == self.currentMessageCount) {
			[multicastDelegate xmppMessageArchiveManagement:self didFinishReceivingMessages:self.currentMessageCount];
			[self resetToDefaults];
		}
	}
	return message;
}

@end
