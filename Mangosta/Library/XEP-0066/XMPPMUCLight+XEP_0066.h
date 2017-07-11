//
//  XMPPMUCLight+XEP_0066.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 10/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPOutOfBandMessaging.h"

@interface XMPPMUCLight (XEP_0066) <XMPPOutOfBandMessagingDelegate>

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message;

@end

@interface XMPPRoomLight (XEP_0066) <XMPPOutOfBandMessagingDelegate>

- (void)sendMessageWithOutOfBandData:(NSData *)outOfBandData MIMEType:(NSString *)MIMEType;

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message;
- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didPrepareToSendOutOfBandDataMessage:(XMPPMessage *)message;

@end
