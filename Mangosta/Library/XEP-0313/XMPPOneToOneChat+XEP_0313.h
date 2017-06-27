//
//  XMPPOneToOneChat+XEP_0313.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 19/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat.h"

@interface XMPPOneToOneChat (XEP_0313) <XMPPMessageArchiveManagementDelegate>

- (void)xmppMessageArchiveManagement:(XMPPMessageArchiveManagement *)xmppMessageArchiveManagement didReceiveMAMMessage:(XMPPMessage *)message;

@end

@protocol XMPPMessageArchiveManagementAwareOneToOneChatDelegate <XMPPOneToOneChatDelegate>

- (void)xmppOneToOneChat:(XMPPOneToOneChat *)sender didReceiveArchivedMessage:(XMPPMessage *)message;

@end
