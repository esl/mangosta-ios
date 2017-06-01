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
}

- (void)discoverInformationAbout:(XMPPJID *)jid;
- (void)discoverItemsAssociatedWith:(XMPPJID *)jid;

@end

@protocol XMPPServiceDiscoveryDelegate

@optional

- (void)xmppServiceDiscovery:(XMPPServiceDiscovery *)sender didDiscoverInformation:(NSArray *)items;
- (void)xmppServiceDiscovery:(XMPPServiceDiscovery *)sender didDiscoverItems:(NSArray *)items;

- (void)xmppServiceDiscovery:(XMPPServiceDiscovery *)sender didFailToDiscover:(XMPPIQ *)iq;

@end