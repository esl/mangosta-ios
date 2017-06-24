//
//  XMPPRetransmissionRoomLightStorageFilter.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPRetransmission.h"

/**
 A storage filter that prevents retransmitted outgoing room messages from being stored in the actual storage.
 */
@interface XMPPRetransmissionRoomLightStorageFilter : NSObject <XMPPRoomLightStorage>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBaseStorage:(id<XMPPRoomLightStorage>)baseStorage xmppRetransmission:(XMPPRetransmission *)xmppRetransmission;

@end
