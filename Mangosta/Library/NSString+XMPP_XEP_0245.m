//
//  NSString+XMPP_XEP_0245.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 24/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "NSString+XMPP_XEP_0245.h"

@implementation NSString (XMPP_XEP_0245)

- (BOOL)hasXMPPMeCommandPrefix
{
    return [self hasPrefix:@"/me "];
}

- (NSString *)xmppMessageBodyStringByTrimmingMeCommand
{
    NSRange meCommandRange = [self rangeOfString:@"/me "];
    return meCommandRange.location == 0 ? [self stringByReplacingCharactersInRange:meCommandRange withString:@""] : [self copy];
}

@end
