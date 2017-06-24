//
//  XMPPOneToOneChat+XMPPRetransmissionDelegate.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPOneToOneChat.h"
#import "XMPPRetransmission.h"

@interface XMPPOneToOneChat (XMPPRetransmissionDelegate) <XMPPRetransmissionDelegate>

- (void)xmppRetransmission:(XMPPRetransmission *)xmppRetransmission didDetectSubmissionFailureForElement:(XMPPElement *)element;

@end
