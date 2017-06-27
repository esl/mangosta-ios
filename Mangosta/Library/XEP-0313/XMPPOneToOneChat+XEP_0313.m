//
//  XMPPOneToOneChat+XEP_0313.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 19/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat+XEP_0313.h"
#import "XMPPMessage+XEP_0313.h"

@interface XMPPOneToOneChat (Protected)

@property (strong, nonatomic, readonly) id<XMPPMessageArchivingStorage> messageArchivingStorage;

@end

@implementation XMPPOneToOneChat (XEP_0313)

- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveMAMMessage:(XMPPMessage *)message
{
    XMPPMessage *archivedMessage = [message messageForForwardedArchiveMessage];
    if (![archivedMessage isChatMessage]) {
        return;
    }
    
    [multicastDelegate xmppOneToOneChat:self didReceiveArchivedMessage:archivedMessage];
}

@end
