//
//  XMPPMessage+XEP_0060.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 15/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPMessage (XEP_0060)

- (BOOL)isPubSubItemsEventMessageFromNode:(NSString *)node;
- (NSArray<NSXMLElement *> *)pubSubItemsEventPayloads;

@end
