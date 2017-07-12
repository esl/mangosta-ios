//
//  XMPPMUCLight+XEP_0066.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 10/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPMUCLight+XEP_0066.h"

// TODO: the implementations here contain repeated framework logic

@implementation XMPPMUCLight (XEP_0066)

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message
{
    if (![message isGroupChatMessage]) {
        return;
    }
    
    XMPPJID *senderJID = [XMPPJID jidWithString:[message from].resource];
    if ([senderJID isEqualToJID:[self.xmppStream myJID] options:XMPPJIDCompareBare]) {
        // Room is broadcasting back a message that has already been handled as outgoing
        return;
    }
    
    // TODO: aim not to initiate the download if not needed
    [xmppOutOfBandMessaging retrieveOutOfBandDataForMessage:message];
}

@end

@implementation XMPPRoomLight (XEP_0066)

- (void)sendMessageWithOutOfBandData:(NSData *)outOfBandData MIMEType:(NSString *)MIMEType
{
    __block XMPPOutOfBandMessaging *outOfBandMessaging;
    [self.xmppStream enumerateModulesOfClass:[XMPPOutOfBandMessaging class] withBlock:^(XMPPModule *module, NSUInteger idx, BOOL *stop) {
        outOfBandMessaging = (XMPPOutOfBandMessaging *)module;
        *stop = YES;
    }];
    NSAssert(outOfBandMessaging, @"XMPPOutOfBandMessaging module not currently registered");
    
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"groupchat" to:self.roomJID elementID:[XMPPStream generateUUID]];
    [message addBody:@""];  // we still want at least an empty body so the message is stored in archives etc.
    [outOfBandMessaging submitOutgoingMessage:message withOutOfBandData:outOfBandData MIMEType:MIMEType];
}

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message
{
    XMPPJID *from = [message from];
    
    if (![self.roomJID isEqualToJID:from options:XMPPJIDCompareBare]){
        return; // Stanza isn't for our room
    }
    
    if (![message isGroupChatMessage] || ![message hasOutOfBandData] ) {
        return;
    }
    
    [xmppRoomLightStorage handleIncomingMessage:message room:self];
}

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didPrepareToSendOutOfBandDataMessage:(XMPPMessage *)message
{
    XMPPJID *to = [message to];
    
    if (![self.roomJID isEqualToJID:to options:XMPPJIDCompareBare]){
        return; // Stanza isn't for our room
    }
    
    if (![message isGroupChatMessage] || ![message hasOutOfBandData] ) {
        return;
    }
    
    [xmppRoomLightStorage handleOutgoingMessage:message room:self];
}

@end
