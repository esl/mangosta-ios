//
//  XMPPRetransmission.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 21/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRetransmission.h"

@interface XMPPRetransmission () <XMPPStreamManagementDelegate>

@property (copy, nonatomic, readonly) NSMutableDictionary<NSUUID *, XMPPElement *> *retransmittedElements;

@end

@implementation XMPPRetransmission

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue storage:(id<XMPPRetransmissionStorage>)storage
{
    self = [super initWithDispatchQueue:queue];
    if (self) {
        _storage = storage;
        _retransmittedElements = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithStorage:(id<XMPPRetransmissionStorage>)storage
{
    return [self initWithDispatchQueue:nil storage:storage];
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    if (![super activate:aXmppStream]) {
        return NO;
    }
    
    [aXmppStream autoAddDelegate:self delegateQueue:self.moduleQueue toModulesOfClass:[XMPPStreamManagement class]];
    return YES;
}

- (void)deactivate
{
    [self.xmppStream removeAutoDelegate:self delegateQueue:self.moduleQueue fromModulesOfClass:[XMPPStreamManagement class]];
    [super deactivate];
}

- (id)xmppStreamManagement:(XMPPStreamManagement *)sender stanzaIdForSentElement:(XMPPElement *)element
{
    [sender requestAck];
    return [self handleTransmissionForElement:element withSubmissionFailureDetected:NO];
}

- (void)xmppStreamManagement:(XMPPStreamManagement *)sender didReceiveAckForStanzaIds:(NSArray *)stanzaIds
{
    [self confirmTransmissionForElementsWithIds:stanzaIds];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    [self handleTransmissionForElement:iq withSubmissionFailureDetected:YES];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    [self handleTransmissionForElement:message withSubmissionFailureDetected:YES];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    [self handleTransmissionForElement:presence withSubmissionFailureDetected:YES];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [sender enumerateModulesOfClass:[XMPPStreamManagement class] withBlock:^(XMPPModule *module, NSUInteger idx, BOOL *stop) {
        NSArray *acknowledgedStanzaIds;
        [(XMPPStreamManagement *)module didResumeWithAckedStanzaIds:&acknowledgedStanzaIds serverResponse:nil];
        
        if (acknowledgedStanzaIds) {
            dispatch_async(self.moduleQueue, ^{
                [self confirmTransmissionForElementsWithIds:acknowledgedStanzaIds];
            });
        }
    }];
    
    [self.storage enumerateMonitoredElementsWithBlock:^(NSUUID *elementId, XMPPElement *element, NSDate *timestamp) {
        dispatch_async(self.moduleQueue, ^{
            [self retransmitElement:element withId:elementId originalTimestamp:timestamp];
        });
    }];
}

- (NSUUID *)handleTransmissionForElement:(XMPPElement *)element withSubmissionFailureDetected:(BOOL)isSubmissionFailureDetected
{
    if (isSubmissionFailureDetected) {
        [multicastDelegate xmppRetransmission:self didDetectSubmissionFailureForElement:element];
    }
    
    NSUUID *retransmittedElementId = [self idForRetransmittedElement:element];
    if (retransmittedElementId) {
        return retransmittedElementId;
    }
    
    NSUUID *elementId = [NSUUID UUID];
    [self.storage storeMonitoredElement:element withId:elementId];
    [multicastDelegate xmppRetransmission:self didBeginMonitoringTransmissionForElement:element];
    
    return elementId;
}

- (void)confirmTransmissionForElementsWithIds:(NSArray<NSUUID *> *)elementIds
{
    NSMutableDictionary *acknowledgedElements = [NSMutableDictionary dictionary];
    [self.storage enumerateMonitoredElementsWithBlock:^(NSUUID *elementId, XMPPElement *element, NSDate *timestamp) {
        if ([elementIds containsObject:elementId]) {
            acknowledgedElements[elementId] = element;
        }
    }];
    
    [self.storage clearMonitoredElementsWithIds:acknowledgedElements.allKeys];
    [self.retransmittedElements removeObjectsForKeys:acknowledgedElements.allKeys];
    
    if (acknowledgedElements.count > 0) {
        [multicastDelegate xmppRetransmission:self didConfirmTransmissionForElements:acknowledgedElements.allValues];
    }
}

- (void)retransmitElement:(XMPPElement *)element withId:(NSUUID *)elementId originalTimestamp:(NSDate *)originalTimestamp
{
    self.retransmittedElements[elementId] = element;
    
    NSDate *stamp = [element delayedDeliveryDate] ?: originalTimestamp;
    
    NSXMLElement *delay = [[NSXMLElement alloc] initWithName:@"delay" xmlns:@"urn:xmpp:delay"];
    [delay addAttributeWithName:@"stamp" stringValue:[stamp xmppDateTimeString]];
    delay.stringValue = @"Retransmission";
    
    [element removeElementForName:@"delay" xmlns:@"urn:xmpp:delay"];
    [element addChild:delay];
    
    [self.xmppStream sendElement:element];
}

- (NSUUID *)idForRetransmittedElement:(XMPPElement *)element
{
    __block NSUUID *result;
    [self.retransmittedElements enumerateKeysAndObjectsUsingBlock:^(NSUUID * _Nonnull key, XMPPElement * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj == element) {
            result = key;
            *stop = YES;
        }
    }];
    return result;
}

@end
