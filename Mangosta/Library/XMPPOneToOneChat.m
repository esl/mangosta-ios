//
//  XMPPOneToOneChat.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat.h"

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@interface XMPPOneToOneChat ()

@property (strong, nonatomic, readonly) id<XMPPMessageArchivingStorage> messageArchivingStorage;

@end

@implementation XMPPOneToOneChat

- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage dispatchQueue:(dispatch_queue_t)queue
{
    self = [super initWithDispatchQueue:queue];
    if (self) {
        _messageArchivingStorage = messageArchivingStorage;
    }
    return self;
}

- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage
{
    return [self initWithMessageArchivingStorage:messageArchivingStorage dispatchQueue:nil];
}

- (id)initWithDispatchQueue:(dispatch_queue_t)queue
{
    return [self initWithMessageArchivingStorage:nil dispatchQueue:queue];
}

- (id)init
{
    return [self initWithMessageArchivingStorage:nil dispatchQueue:nil];
}

- (void)sendMessageTo:(XMPPJID *)recipientJID withBody:(NSString *)body
{
    // TODO: [pwe] bare/full recipient JID, threads according to https://xmpp.org/rfcs/rfc6121.html#message-chat
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:recipientJID];
    [message addBody:body];
    
    [self.xmppStream sendElement:message];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    XMPPLogTrace();
    [self handleMessage:message outgoing:YES inStream:sender];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    XMPPLogTrace();
    [self handleMessage:message outgoing:NO inStream:sender];
}

- (void)handleMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing inStream:(XMPPStream *)stream
{
    if (![message isChatMessage]) {
        return;
    }
    
    [self.messageArchivingStorage archiveMessage:message outgoing:NO xmppStream:stream];
}

@end
