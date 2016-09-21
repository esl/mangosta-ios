//
//  XMPPMessage+XEP_0245.m
//
//  Created by Sergio Abraham on 9/9/16.
//  Copyright © 2016 Inaka. All rights reserved.
//
//

#import "XMPPMessage+XEP_0245.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XEP_0203.h"

/**
 XEP-0245: The /me Command
 http://xmpp.org/extensions/xep-0245.html
 
 This specification aims to handle the /me command in this way:
 
 - If a message is received having its first four chars "/me " then 
 - Whether to copy a message to other resources.
 - Whether to store a message that would not have been stored under normal conditions
 */

@implementation XMPPMessage (XEP_0245)

- (BOOL)isMessageStartingWithMeCommand {
	if ([[[[self elementsForName:@"body"] firstObject] stringValue] hasPrefix:@"/me "]) {
		return YES;
	}
	return NO;
}

@end
