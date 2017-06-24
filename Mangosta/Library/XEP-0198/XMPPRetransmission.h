//
//  XMPPRetransmission.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 21/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@protocol XMPPRetransmissionStorage;

/**
 A module that attempts to retransmit any pending stanzas upon successful stream reauthentication.
 
 The handled scenarios are:
 - element failed to be submitted, as per -xmppStream:didFailToSendXXX: callbacks
 - element was submitted, but not acknowledged by the server
 
 This module works in tandem with XMPPStreamManagement, relying on ACKing of outgoing elements.
 */
@interface XMPPRetransmission : XMPPModule

@property (strong, nonatomic, readonly) id<XMPPRetransmissionStorage> storage;

- (id)init NS_UNAVAILABLE;
- (id)initWithDispatchQueue:(dispatch_queue_t)queue NS_UNAVAILABLE;

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue storage:(id<XMPPRetransmissionStorage>)storage NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStorage:(id<XMPPRetransmissionStorage>)storage;

// TODO: API to manually trigger retransmission/control automatic retransmission

@end

@protocol XMPPRetransmissionDelegate <NSObject>

@optional
- (void)xmppRetransmission:(XMPPRetransmission *)xmppRetransmission didBeginMonitoringTransmissionForElement:(XMPPElement *)element;
- (void)xmppRetransmission:(XMPPRetransmission *)xmppRetransmission didDetectSubmissionFailureForElement:(XMPPElement *)element;
- (void)xmppRetransmission:(XMPPRetransmission *)xmppRetransmission didConfirmTransmissionForElements:(NSArray<XMPPElement *> *)elements;

@end

/**
 A protocol for storage objects that keep track of pending stanzas to be retransmitted by XMPPRetransmission module.
 */
@protocol XMPPRetransmissionStorage <NSObject>

- (void)storeMonitoredElement:(XMPPElement *)element withId:(NSUUID *)elementId;
- (void)enumerateMonitoredElementsWithBlock:(void (^)(NSUUID *elementId, XMPPElement *element, NSDate *timestamp))enumerationBlock;
- (void)clearMonitoredElementsWithIds:(NSArray<NSUUID *> *)elementIds;

@end
