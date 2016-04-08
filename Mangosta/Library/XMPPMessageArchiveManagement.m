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

#define XMLSN_XMPP_MAM @"ur:xmpp:mam:tmp"

@implementation XMPPMessageArchiveManagement

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
	self = [super initWithDispatchQueue:queue];
	
	if (self) {
		
	}
	
	return self;
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPMessage *)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
	if ([message isMessageArchive]) {
		XMPPMessage *messageArchiveForwardedMessage = [message messageForForwardedArchiveMessage];
		
		[multicastDelegate xmppMessageArchiveManagement:self didReceiveMessage:messageArchiveForwardedMessage];
	}
	return message;
}

@end
