//
//  XMPPOneToOneChat+XMPPRetransmissionDelegate.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat+XMPPRetransmissionDelegate.h"
#import "XMPPOneToOneChat+Protected.h"

@implementation XMPPOneToOneChat (XMPPRetransmissionDelegate)

- (void)xmppRetransmission:(XMPPRetransmission *)xmppRetransmission didDetectSubmissionFailureForElement:(XMPPElement *)element
{
    if ([element isKindOfClass:[XMPPMessage class]]) {
        [self handleMessage:(XMPPMessage *)element outgoing:YES inStream:self.xmppStream];
    }
}

@end
