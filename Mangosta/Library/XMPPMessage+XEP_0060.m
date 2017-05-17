//
//  XMPPMessage+XEP_0060.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 15/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPMessage+XEP_0060.h"

@implementation XMPPMessage (XEP_0060)

- (BOOL)isPubSubItemsEventMessageFromNode:(NSString *)node
{
    return [[[self pubSubEventItems] attributeStringValueForName:@"node"] isEqualToString:node];
}

- (NSArray<NSXMLElement *> *)pubSubItemsEventPayloads
{
    NSXMLElement *pubSubEventItems = [self pubSubEventItems];
    if (!pubSubEventItems) {
        return nil;
    }
    
    NSMutableArray *payloads = [NSMutableArray array];
    for (NSXMLElement *item in [pubSubEventItems elementsForName:@"item"]) {
        for (NSXMLNode *node in item.children) {
            if (node.kind == NSXMLElementKind) {
                [payloads addObject:node];
            }
        }
    }
    
    return payloads;
}

- (NSXMLElement *)pubSubEventItems
{
    return [[self elementForName:@"event" xmlns:XMLNS_PUBSUB_EVENT] elementForName:@"items"];
}

@end
