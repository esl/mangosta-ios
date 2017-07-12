//
//  XMPPOneToOneChat.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat.h"
#import "XMPPOneToOneChat+Protected.h"

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@interface XMPPOneToOneChat ()

@property (strong, nonatomic, readonly) id<XMPPMessageArchivingStorage> messageArchivingStorage;
@property (strong, nonatomic, readonly) NSMutableArray<XMPPOneToOneChatSession *> *sessions;

@end

@interface XMPPOneToOneChatSession ()

@property (strong, nonatomic, readonly) XMPPStream *xmppStream;
@property (strong, nonatomic, readonly) XMPPJID *userJID;

- (instancetype)initWithStream:(XMPPStream *)xmppStream userJID:(XMPPJID *)userJID;
- (void)handleIncomingMessage:(XMPPMessage *)message;

@end

@implementation XMPPOneToOneChat (Protected)

- (void)handleMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing inStream:(XMPPStream *)stream
{
    if (![message isChatMessage]) {
        return;
    }
    
    if (!isOutgoing) {
        [[self sessionForUserJID:[message from]] handleIncomingMessage:message];
    }
    
    [self.messageArchivingStorage archiveMessage:message outgoing:isOutgoing xmppStream:stream];
}

@end

@implementation XMPPOneToOneChat

- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage dispatchQueue:(dispatch_queue_t)queue
{
    self = [super initWithDispatchQueue:queue];
    if (self) {
        _messageArchivingStorage = messageArchivingStorage;
        _sessions = [[NSMutableArray alloc] init];
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

- (XMPPOneToOneChatSession *)sessionForUserJID:(XMPPJID *)userJID
{
    __block XMPPOneToOneChatSession *session;
    
    dispatch_block_t block = ^{
        NSUInteger existingSessionIndex = [self.sessions indexOfObjectPassingTest:^BOOL(XMPPOneToOneChatSession * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.userJID isEqualToJID:userJID options:XMPPJIDCompareBare];
        }];
        if (existingSessionIndex != NSNotFound) {
            session = self.sessions[existingSessionIndex];
        } else {
            session = [[XMPPOneToOneChatSession alloc] initWithStream:self.xmppStream userJID:[userJID bareJID]];
            [self.sessions addObject:session];
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return session;
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

@end

@implementation XMPPOneToOneChatSession (Protected)

- (XMPPStream *)oneToOneChatStream
{
    return self.xmppStream;
}

- (XMPPMessage *)outgoingMessageWithBody:(NSString *)body
{
    // TODO: [pwe] bare/full recipient JID, threads according to https://xmpp.org/rfcs/rfc6121.html#message-chat
    XMPPMessage *message = [[XMPPMessage alloc] initWithType:@"chat" to:self.userJID elementID:[XMPPStream generateUUID]];
    [message addBody:body];
    return message;
}

@end

@implementation XMPPOneToOneChatSession

- (instancetype)initWithStream:(XMPPStream *)xmppStream userJID:(XMPPJID *)userJID
{
    self = [super init];
    if (self) {
        _xmppStream = xmppStream;
        _userJID = userJID;
    }
    return self;
}

- (void)sendMessageWithBody:(NSString *)body
{
    [self.xmppStream sendElement:[self outgoingMessageWithBody:body]];
}

- (void)handleIncomingMessage:(XMPPMessage *)message
{
    // TODO
}

@end
