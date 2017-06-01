//
//  XMPPRoster+XEP_0245.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 24/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRoster+XEP_0245.h"
#import "XMPPStream+XEP_0245.h"

@implementation XMPPRoster (XEP_0245)

- (NSString *)meCommandSubstitutionForMessage:(XMPPMessage *)message
{
    NSString *substitutionString = [self.xmppStream meCommandSubstitutionStringForMessage:message];
    XMPPJID *lookupJID = [XMPPJID jidWithString:[self.xmppStream meCommandSubstitutionStringForMessage:message]];
    if (!lookupJID) {
        return substitutionString;
    }
    
    NSString *nickname;
    [self.xmppRosterStorage getSubscription:NULL ask:NULL nickname:&nickname groups:NULL forJID:lookupJID xmppStream:self.xmppStream];
    return nickname ?: lookupJID.user;
}

@end
