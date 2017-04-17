//
//  XMPPPushNotifications.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 04/04/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPPushNotifications.h"
#import "XMPPLogging.h"
#import "XMPPIDTracker.h"
#import "XMPPIQ+XEP_0357.h"

static const int xmppLogLevel = XMPP_LOG_LEVEL_VERBOSE | XMPP_LOG_FLAG_TRACE;

@interface XMPPPushNotifications () <XMPPStreamDelegate>

@property (assign, readonly) XMPPPushNotificationsEnvironment environment;
@property (strong, readonly) XMPPIDTracker *responseTracker;

@end

@implementation XMPPPushNotifications

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue pubSubServiceJid:(XMPPJID *)serviceJid nodeName:(NSString *)nodeName environment:(XMPPPushNotificationsEnvironment)environment
{
    self = [super initWithDispatchQueue:queue];
    if (self) {
        _pubSubServiceJid = serviceJid;
        _nodeName = [nodeName copy];
        _environment = environment;
        _responseTracker = [[XMPPIDTracker alloc] initWithStream:self.xmppStream dispatchQueue:self.moduleQueue];
    }
    return self;
}

- (instancetype)initWithPubSubServiceJid:(XMPPJID *)serviceJid nodeName:(NSString *)nodeName environment:(XMPPPushNotificationsEnvironment)environment
{
    return [self initWithDispatchQueue:nil pubSubServiceJid:serviceJid nodeName:nodeName environment:environment];
}

- (void)enableWithDeviceTokenString:(NSString *)deviceTokenString
{
    XMPPLogTrace();
    
    dispatch_async(moduleQueue, ^{
        NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:@{ @"service": @"apns",
                                                                                          @"device_id": deviceTokenString }];
        
        switch (self.environment) {
            case XMPPPushNotificationsEnvironmentProduction:
                options[@"mode"] = @"prod";
                break;
                
            case XMPPPushNotificationsEnvironmentSandbox:
                options[@"mode"] = @"dev";
                
            default:
                break;
        }
        
        XMPPElement *enableIq = [XMPPIQ enableNotificationsElementWithJID:self.pubSubServiceJid
                                                                     node:self.nodeName
                                                                  options:options];
        
        [self.responseTracker addID:[enableIq elementID]
                             target:self
                           selector:@selector(handleEnableResponse:withInfo:)
                            timeout:60.0];
        
        [self.xmppStream sendElement:enableIq];
        
        XMPPLogVerbose(@"Enabling push notifications at: %@, node: %@ with device token %@ in mode: %@",
                       [self.pubSubServiceJid full], self.nodeName, deviceTokenString, options[@"mode"] ?: @"<default>");
    });
}

- (void)disable
{
    XMPPLogTrace();
    
    dispatch_async(moduleQueue, ^{
        XMPPElement *disableIq = [XMPPIQ disableNotificationsElementWithJID:self.pubSubServiceJid node:self.nodeName];
        
        [self.responseTracker addID:[disableIq elementID]
                             target:self
                           selector:@selector(handleDisableResponse:withInfo:)
                            timeout:60.0];
        
        [self.xmppStream sendElement:disableIq];
        
        XMPPLogVerbose(@"Disabling push notifications at %@, node: %@", [self.pubSubServiceJid full], self.nodeName);
    });
}

- (void)deactivate
{
    XMPPLogTrace();
    
    dispatch_block_t block = ^{ @autoreleasepool {
        [self.responseTracker removeAllIDs];
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    [super deactivate];
}


- (void)handleEnableResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    XMPPLogTrace();
    
    if ([[iq type] isEqualToString:@"result"]) {
        XMPPLogVerbose(@"Push notifications successfully enabled");
        [multicastDelegate xmppPushNotificationsDidEnable:self];
    } else if ([[iq type] isEqualToString:@"error"]) {
        XMPPLogVerbose(@"Failed to enable push notifications");
        [multicastDelegate xmppPushNotifications:self didFailToEnableWithErrorResult:iq];
    }
}

- (void)handleDisableResponse:(XMPPIQ *)iq withInfo:(id <XMPPTrackingInfo>)info
{
    XMPPLogTrace();
    
    if ([[iq type] isEqualToString:@"result"]) {
        XMPPLogVerbose(@"Push notifications successfully disabled");
        [multicastDelegate xmppPushNotificationsDidDisable:self];
    } else if ([[iq type] isEqualToString:@"error"]) {
        XMPPLogVerbose(@"Failed to disable push notifications");
        [multicastDelegate xmppPushNotifications:self didFailToDisableWithErrorResult:iq];
    }
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSString *type = [iq type];
    
    if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"]) {
        return [self.responseTracker invokeForID:[iq elementID] withObject:iq];
    }
    
    return NO;
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    XMPPLogTrace();
    [self.responseTracker removeAllIDs];
}

@end
