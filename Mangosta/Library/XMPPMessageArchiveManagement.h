//
//  XMPPMessageArchiveManagement.h
//  Mangosta
//
//  Created by Tom Ryan on 4/8/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@class XMPPIDTracker;
@class XMPPMessage;

@interface XMPPMessageArchiveManagement : XMPPModule {
	XMPPIDTracker *xmppIDTracker;
	BOOL retrievingMessageArchive;
}

- (void)retrieveMessageArchiveFrom:(XMPPJID *)userJID withPageSize:(NSInteger)pageSize;

@end

@protocol XMPPMessageArchiveManagementDelegate <NSObject>
- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveMessageCount:(NSInteger)messageCount;
- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didFinishReceivingMessages:(NSInteger)messageCount;
- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveMessage:(XMPPMessage *)message;
- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveError:(DDXMLElement *)error;
@end