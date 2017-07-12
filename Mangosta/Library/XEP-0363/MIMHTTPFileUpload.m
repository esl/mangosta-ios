//
//  MIMHTTPFileUpload.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 11/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "MIMHTTPFileUpload.h"

@implementation MIMHTTPFileUpload

- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq
{
    NSXMLElement *slot = [iq elementForName:@"slot" xmlns:@"urn:xmpp:http:upload"];
    if (!slot) {
        return iq;
    }
    
    // Double escaping (https://redmine.erlang-solutions.com/issues/17349)
    for (NSString *URLElementName in @[@"put", @"get"]) {
        NSXMLElement *URLElement = [slot elementForName:URLElementName];
        NSXMLElement *fixedStringValueURLElement = [[NSXMLElement alloc] initWithXMLString:[NSString stringWithFormat:@"<fix>%@</fix>", URLElement.stringValue] error:nil];
        if (fixedStringValueURLElement.stringValue) {
            URLElement.stringValue = fixedStringValueURLElement.stringValue;
        }
    }
    
    // Superfluous GET parameters (https://redmine.erlang-solutions.com/issues/17351)
    NSXMLElement *getElement = [slot elementForName:@"get"];
    NSURLComponents *getURLComponents = [[NSURLComponents alloc] initWithString:getElement.stringValue];
    getURLComponents.query = nil;
    getElement.stringValue = getURLComponents.string;
    
    return iq;
}

@end
