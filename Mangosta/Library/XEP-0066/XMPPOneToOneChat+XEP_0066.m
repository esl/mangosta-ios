//
//  XMPPOneToOneChat+XEP_0066.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 07/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat+XEP_0066.h"
#import "XMPPOneToOneChat+Protected.h"
#import "XMPPOutOfBandMessaging.h"

@implementation XMPPOneToOneChat (XEP_0066)

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message
{
    if (![message isChatMessage]) {
        return;
    }
    
    // TODO: aim not to initiate the download unconditionally
    [xmppOutOfBandMessaging retrieveOutOfBandDataForMessage:message];
}

@end

@implementation XMPPOneToOneChatSession (XEP_0066)

- (void)sendMessageWithOutOfBandData:(NSData *)outOfBandData MIMEType:(NSString *)MIMEType
{
    __block XMPPOutOfBandMessaging *outOfBandMessaging;
    [self.oneToOneChatStream enumerateModulesOfClass:[XMPPOutOfBandMessaging class] withBlock:^(XMPPModule *module, NSUInteger idx, BOOL *stop) {
        outOfBandMessaging = (XMPPOutOfBandMessaging *)module;
        *stop = YES;
    }];
    NSAssert(outOfBandMessaging, @"XMPPOutOfBandMessaging module not currently registered");
    
    [outOfBandMessaging submitOutgoingMessage:[self outgoingMessage] withOutOfBandData:outOfBandData MIMEType:MIMEType];
}

@end
