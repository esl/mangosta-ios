//
//  XMPPLastMessageCorrection.h
//  Mangosta
//
//  Created by Sergio Abraham on 8/3/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@class XMPPIDTracker;

@interface XMPPLastMessageCorrection : XMPPModule {
	XMPPIDTracker *xmppIDTracker;
}

- (void)discoverInformationAbout:(XMPPJID *)jid;
- (void)discoverItemsAssociatedWith:(XMPPJID *)jid;

@end

@protocol XMPPServiceDiscoveryDelegate

@optional

- (void)xmppServiceDiscovery:(XMPPLastMessageCorrection *)sender didDiscoverInformation:(NSArray *)items;
- (void)xmppServiceDiscovery:(XMPPLastMessageCorrection *)sender didDiscoverItems:(NSArray *)items;

- (void)xmppServiceDiscovery:(XMPPLastMessageCorrection *)sender didFailToDiscover:(XMPPIQ *)iq;

@end