//
//  NSXMLElement+XEP_0277.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 15/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "NSXMLElement+XEP_0277.h"

NSString *const XMPPPubSubDefaultMicroblogNode = @"urn:xmpp:microblog:0";
NSString *const XMPPCapabilitiesMicroblogImplicitSubscription = @"urn:xmpp:microblog:0+notify";

static NSString *const XMLNamespaceAtom = @"http://www.w3.org/2005/Atom";

@implementation NSXMLElement (XEP_0277)

+ (instancetype)microblogEntryWithTitle:(NSString *)titleText authorName:(NSString *)authorName authorJID:(XMPPJID *)authorJID publishedDate:(NSDate *)publishedDate updatedDate:(NSDate *)updatedDate
{
    NSXMLElement *entry = [[NSXMLElement alloc] initWithName:@"entry" xmlns:XMLNamespaceAtom];
    
    [entry addChild:[[NSXMLElement alloc] initWithName:@"id" stringValue:[@"urn:uuid:" stringByAppendingString:[NSUUID UUID].UUIDString]]];
    
    NSXMLElement *title = [[NSXMLElement alloc] initWithName:@"title" stringValue:titleText];
    [title addAttributeWithName:@"type" stringValue:@"text"];
    [entry addChild:title];
    
    NSXMLElement *author = [[NSXMLElement alloc] initWithName:@"author"];
    [author addChild:[[NSXMLElement alloc] initWithName:@"name" stringValue:authorName]];
    [author addChild:[[NSXMLElement alloc] initWithName:@"uri" stringValue:[@"xmpp:" stringByAppendingString:[authorJID bare]]]];
    [entry addChild:author];
    
    [entry addChild:[[NSXMLElement alloc] initWithName:@"published" stringValue:[publishedDate xmppDateTimeString]]];
    [entry addChild:[[NSXMLElement alloc] initWithName:@"updated" stringValue:[updatedDate xmppDateTimeString]]];
    
    return entry;
}

- (BOOL)isMicroblogEntry
{
    return [self.name isEqualToString:@"entry"] && [self.xmlns isEqualToString:XMLNamespaceAtom];
}

- (NSString *)microblogEntryID
{
    return [self elementForName:@"id"].stringValue;
}

- (NSString *)microblogEntryTitle
{
    return [self elementForName:@"title"].stringValue;
}

- (NSString *)microblogEntryAuthorName
{
    return [[self elementForName:@"author"] elementForName:@"name"].stringValue;
}

- (NSDate *)microblogEntryPublishedDate
{
    return [NSDate dateWithXmppDateTimeString:[self elementForName:@"published"].stringValue];
}

- (NSDate *)microblogEntryUpdatedDate
{
    return [NSDate dateWithXmppDateTimeString:[self elementForName:@"updated"].stringValue];
}

@end
