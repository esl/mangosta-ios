//
//  XMPPRoomLight+XEP_0313.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRoomLight+XEP_0313.h"
#import "XMPPMessage+XEP_0313.h"

@implementation XMPPRoomLight (XEP_0313)

- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveMAMMessage:(XMPPMessage *)message
{
    XMPPMessage *archivedMessage = [message messageForForwardedArchiveMessage];
    if (![archivedMessage isGroupChatMessage]) {
        return;
    }
    
    XMPPJID *from = [archivedMessage from];
    if (![self.roomJID isEqualToJID:from options:XMPPJIDCompareBare]){
        return;
    }

    [multicastDelegate xmppRoomLight:self didReceiveArchivedMessage:archivedMessage withTimestamp:[NSDate dateWithXmppDateTimeString:[message delayStamp]]];
}

@end
