//
//  XMPPServiceDiscovery+XEP_0357.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 04/04/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPServiceDiscovery.h"

@interface XMPPElement (XMPPServiceDiscovery_XEP_0357)

- (BOOL)isPushNotificationFeatureElement;

@end

// Swift does not play well with KissXML's #define NSXMLElement DDXMLElement hack
@interface DDXMLElement (XMPPServiceDiscovery_XEP_0357)

- (BOOL)isPushNotificationFeatureElement;

@end
