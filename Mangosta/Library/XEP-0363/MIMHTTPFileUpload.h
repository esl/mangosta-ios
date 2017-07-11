//
//  MIMHTTPFileUpload.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 11/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

/**
 A subclass to work around some MongooseIM bugs.
 */
@interface MIMHTTPFileUpload : XMPPHTTPFileUpload

- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq;

@end
