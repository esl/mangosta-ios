//
//  XMPPStream+XEP_0245.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPStream+XEP_0245.h"

@implementation XMPPStream (XEP_0245)

- (NSString *)meCommandSubstitutionStringForMessage:(XMPPMessage *)message
{
    if ([message isGroupChatMessage]) {
        return [message from].resource;
    } else {
        return [[message from] ?: self.myJID bare];
    }
}

@end
