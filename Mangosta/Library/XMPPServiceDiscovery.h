//
//  XMPPServiceDiscovery.h
//  Mangosta
//
//  Created by Andres Canal on 4/27/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@class XMPPIDTracker;

@interface XMPPServiceDiscovery : XMPPModule {
	XMPPIDTracker *xmppIDTracker;
	BOOL retrievingMessageArchive;
}

- (void)fetchItemsForJID:(XMPPJID *)jid;

@end

@protocol XMPPServiceDiscoveryDelegate

@optional

- (void)xmppServiceDiscovery:(XMPPServiceDiscovery *)sender collectingMyCapabilities:(NSXMLElement *)query;

@end