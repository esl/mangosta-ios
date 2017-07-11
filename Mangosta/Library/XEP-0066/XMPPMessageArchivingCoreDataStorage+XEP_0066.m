//
//  XMPPMessageArchivingCoreDataStorage+XEP_0066.m
//  Mangosta
//
//  Created by Piotrek on 08/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPMessageArchivingCoreDataStorage+XEP_0066.h"

static NSString * const XMPPMessageOutOfBandElementXPath = @"./*[namespace-uri()='jabber:x:oob' and local-name()='x']";

@implementation XMPPMessageArchivingCoreDataStorage (XEP_0066)

- (BOOL)isOutOfBandMessageArchivingEnabled
{
    return [self.relevantContentXPaths containsObject:XMPPMessageOutOfBandElementXPath];
}

- (void)setOutOfBandMessageArchivingEnabled:(BOOL)outOfBandMessageArchivingEnabled
{
    NSMutableSet *relevantContextXPaths = [[NSMutableSet alloc] initWithArray:self.relevantContentXPaths];
    if (outOfBandMessageArchivingEnabled) {
        [relevantContextXPaths addObject:XMPPMessageOutOfBandElementXPath];
    } else {
        [relevantContextXPaths removeObject:XMPPMessageOutOfBandElementXPath];
    }
    self.relevantContentXPaths = relevantContextXPaths.allObjects;
}

@end
