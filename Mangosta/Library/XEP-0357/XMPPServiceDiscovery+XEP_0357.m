//
//  XMPPServiceDiscovery+XEP_0357.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 04/04/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPServiceDiscovery+XEP_0357.h"

@implementation DDXMLElement (XMPPServiceDiscovery_XEP_0357)

- (BOOL)isPushNotificationFeatureElement
{
    return [self.name isEqualToString:@"feature"] ? [[self attributesAsDictionary][@"var"] isEqualToString:@"urn:xmpp:push:0"]: NO;
}

@end
