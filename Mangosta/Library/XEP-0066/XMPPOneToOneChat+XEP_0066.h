//
//  XMPPOneToOneChat+XEP_0066.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 07/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat.h"
#import "XMPPOutOfBandMessaging.h"

@interface XMPPOneToOneChat (XEP_0066) <XMPPOutOfBandMessagingDelegate>

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message;

@end

@interface XMPPOneToOneChatSession (XEP_0066)

- (void)sendMessageWithOutOfBandData:(NSData *)outOfBandData MIMEType:(NSString *)MIMEType;

@end
