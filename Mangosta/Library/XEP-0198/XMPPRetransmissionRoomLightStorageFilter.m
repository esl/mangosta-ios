//
//  XMPPRetransmissionRoomLightStorageFilter.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRetransmissionRoomLightStorageFilter.h"
#import "XMPPRetransmission+XMPPMessageStorageFiltering.h"

@interface XMPPRetransmissionRoomLightStorageFilter ()

@property (strong, nonatomic, readonly) id<XMPPRoomLightStorage> baseStorage;
@property (strong, nonatomic, readonly) XMPPRetransmission *xmppRetransmission;

@end

@implementation XMPPRetransmissionRoomLightStorageFilter

- (instancetype)initWithBaseStorage:(id<XMPPRoomLightStorage>)baseStorage xmppRetransmission:(XMPPRetransmission *)xmppRetransmission
{
    self = [super init];
    if (self) {
        _baseStorage = baseStorage;
        _xmppRetransmission = xmppRetransmission;
    }
    return self;
}

- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoomLight *)room
{
    [self.baseStorage handleIncomingMessage:message room:room];
}

- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoomLight *)room
{
    if ([self.xmppRetransmission isRetransmittingElement:message]) {
        return;
    }
    
    [self.baseStorage handleOutgoingMessage:message room:room];
}

@end
