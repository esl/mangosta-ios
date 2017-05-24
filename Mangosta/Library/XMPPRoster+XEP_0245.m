//
//  XMPPRoster+XEP_0245.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 24/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRoster+XEP_0245.h"
#import "XMPPMessage+XEP_0245.h"

@implementation XMPPRoster (XEP_0245)

- (NSString *)meCommandSubstitutionForMessage:(XMPPMessage *)message
{
    XMPPJID *lookupJID = [message meCommandSubstitutionUserJID];
    if (!lookupJID) {
        return nil;
    }
    
    NSString *substitution;
    [self.xmppRosterStorage getSubscription:NULL ask:NULL nickname:&substitution groups:NULL forJID:lookupJID xmppStream:self.xmppStream];
    return substitution;
}

@end
