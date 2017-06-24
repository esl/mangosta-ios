//
//  XMPPRoomLight+XMPPRetransmissionDelegate.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRoomLight+XMPPRetransmissionDelegate.h"

@implementation XMPPRoomLight (XMPPRetransmissionDelegate)

- (void)xmppRetransmission:(XMPPRetransmission *)xmppRetransmission didDetectSubmissionFailureForElement:(XMPPElement *)element
{
    if ([element isKindOfClass:[XMPPMessage class]]) {
        // TODO: common code with -xmppStream:didSendMessage: implementation
        if (![self.roomJID isEqualToJID:[element to] options:XMPPJIDCompareBare]){
            return;
        }
        
        if ([(XMPPMessage *)element isGroupChatMessageWithBody]){
            [xmppRoomLightStorage handleOutgoingMessage:(XMPPMessage *)element room:self];
        }
    }
}

@end
