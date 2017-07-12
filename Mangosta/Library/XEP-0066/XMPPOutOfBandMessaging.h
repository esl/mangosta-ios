//
//  XMPPOutOfBandMessaging.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 28/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@protocol XMPPOutOfBandMessagingTransferHandler, XMPPOutOfBandMessagingStorage;

@interface XMPPOutOfBandMessaging : XMPPModule

@property (strong, nonatomic, readonly) id<XMPPOutOfBandMessagingTransferHandler> transferHandler;
@property (strong, nonatomic, readonly) id<XMPPOutOfBandMessagingStorage> storage;

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue transferHandler:(id<XMPPOutOfBandMessagingTransferHandler>)transferHandler storage:(id<XMPPOutOfBandMessagingStorage>)storage NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTransferHandler:(id<XMPPOutOfBandMessagingTransferHandler>)transferHandler storage:(id<XMPPOutOfBandMessagingStorage>)storage;

- (id)init NS_UNAVAILABLE;
- (id)initWithDispatchQueue:(dispatch_queue_t)queue NS_UNAVAILABLE;

- (void)submitOutgoingMessage:(XMPPMessage *)message withOutOfBandData:(NSData *)data MIMEType:(NSString *)MIMEType;
- (void)retrieveOutOfBandDataForMessage:(XMPPMessage *)message;

- (NSProgress *)dataTransferProgressForMessage:(XMPPMessage *)message;
- (NSError *)dataTransferErrorForMessage:(XMPPMessage *)message;

@end

@protocol XMPPOutOfBandMessagingDelegate <NSObject>

@optional

- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didReceiveOutOfBandDataMessage:(XMPPMessage *)message NS_SWIFT_NAME(xmppOutOfBandMessaging(_:didReceiveOutOfBandDataMessage:));
- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didPrepareToSendOutOfBandDataMessage:(XMPPMessage *)message NS_SWIFT_NAME(xmppOutOfBandMessaging(_:didPrepareToSendOutOfBandDataMessage:));
- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didBeginDataTransferForMessage:(XMPPMessage *)message NS_SWIFT_NAME(xmppOutOfBandMessaging(_:didBeginDataTransferFor:));
- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didPrepareDataTransferStorageEntryForMessage:(XMPPMessage *)message NS_SWIFT_NAME(xmppOutOfBandMessaging(_:didPrepareDataTransferStorageEntryFor:));
- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didCompleteDataTransferForMessage:(XMPPMessage *)message NS_SWIFT_NAME(xmppOutOfBandMessaging(_:didCompleteDataTransferFor:));
- (void)xmppOutOfBandMessaging:(XMPPOutOfBandMessaging *)xmppOutOfBandMessaging didFailDataTransferForMessage:(XMPPMessage *)message NS_SWIFT_NAME(xmppOutOfBandMessaging(_:didFailDataTransferFor:));

@end
