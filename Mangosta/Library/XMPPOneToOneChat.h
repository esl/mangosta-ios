//
//  XMPPOneToOneChat.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@class XMPPOneToOneChatSession;

@interface XMPPOneToOneChat : XMPPModule

- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage dispatchQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage;

- (void)sendMessageTo:(XMPPJID *)recipientJID withBody:(NSString *)body;
- (XMPPOneToOneChatSession *)sessionForUserJID:(XMPPJID *)userJID;

@end

@interface XMPPOneToOneChatSession : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (void)sendMessageWithBody:(NSString *)body;

// TODO: API to close a session

@end

// TODO: the delegate protocol
