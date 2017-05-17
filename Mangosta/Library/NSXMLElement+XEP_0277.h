//
//  NSXMLElement+XEP_0277.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 15/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

extern NSString *const XMPPPubSubDefaultMicroblogNode;
extern NSString *const XMPPCapabilitiesMicroblogImplicitSubscription;

@interface NSXMLElement (XEP_0277)

- (BOOL)isMicroblogEntry;

@end
