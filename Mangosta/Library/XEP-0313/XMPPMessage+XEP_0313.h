//
//  XMPPMessage+XEP_0313.h
//  Mangosta
//
//  Created by Tom Ryan on 4/8/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPMessage.h>

@interface XMPPMessage (XEP_0313)
- (BOOL)isMessageArchive;

- (XMPPMessage *) messageForForwardedArchiveMessage;
- (NSString *) resultId;
- (NSXMLElement *) delayElement;
- (NSString *) delayStamp;

@end
