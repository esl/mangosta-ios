//
//  XMPPRoomLight+XEP_0313.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPRoomLight (XEP_0313) <XMPPMessageArchiveManagementDelegate>

- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveMAMMessage:(XMPPMessage *)message;

@end

@protocol XMPPMessageArchiveManagementAwareRoomStorage <NSObject>

- (void)importRemoteArchiveMessage:(XMPPMessage *)message room:(XMPPRoomLight *)room fromStream:(XMPPStream *)stream;

@end
