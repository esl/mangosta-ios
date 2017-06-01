//
//  MIMPushNotificationsPubSub.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 21/04/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "MIMPushNotificationsPubSub.h"
#import <XMPPFramework/XMPPIQ+XEP_0060.h>

@interface MIMPushNotificationsPubSub (PrivateMethodsAccess)

- (NSXMLElement *)formForOptions:(NSDictionary *)options withFromType:(NSString *)formTypeValue;

@end

@implementation MIMPushNotificationsPubSub

- (NSString *)createNode:(NSString *)aNode withOptions:(NSDictionary *)options
{
    if (aNode == nil) return nil;
    
    // In-case aNode is mutable
    NSString *node = [aNode copy];
    
    // Generate uuid and add to dict
    NSString *uuid = [xmppStream generateUUID];
    dispatch_async(moduleQueue, ^{
        NSMutableDictionary *createDict = [self valueForKey:@"createDict"];
        createDict[uuid] = node;
    });
    
    // <iq type='set' from='hamlet@denmark.lit/elsinore' to='pubsub.shakespeare.lit' id='create1'>
    //   <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    //     <create node='princely_musings'/>
    //     <configure>
    //       <x xmlns='jabber:x:data' type='submit'>
    //         <field var='FORM_TYPE' type='hidden'>
    //           <value>http://jabber.org/protocol/pubsub#node_config</value>
    //         </field>
    //         <field var='pubsub#title'><value>Princely Musings (Atom)</value></field>
    //         <field var='pubsub#deliver_notifications'><value>1</value></field>
    //         <field var='pubsub#deliver_payloads'><value>1</value></field>
    //         <field var='pubsub#persist_items'><value>1</value></field>
    //         <field var='pubsub#max_items'><value>10</value></field>
    //         ...
    //       </x>
    //     </configure>
    //   </pubsub>
    // </iq>
    
    NSXMLElement *create = [NSXMLElement elementWithName:@"create"];
    [create addAttributeWithName:@"node" stringValue:node];
    [create addAttributeWithName:@"type" stringValue:@"push"];  // MongooseIM-specific
    
    NSXMLElement *pubsub = [NSXMLElement elementWithName:@"pubsub" xmlns:XMLNS_PUBSUB];
    [pubsub addChild:create];
    
    if (options)
    {
        // Example from XEP-0060 section 8.1.3 show above
        
        NSXMLElement *x = [self formForOptions:options withFromType:XMLNS_PUBSUB_NODE_CONFIG];
        
        NSXMLElement *configure = [NSXMLElement elementWithName:@"configure"];
        [configure addChild:x];
        
        [pubsub addChild:configure];
    }
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:[self valueForKey:@"serviceJID"] elementID:uuid];
    [iq addChild:pubsub];
    
    [xmppStream sendElement:iq];
    return uuid;
}

@end
