//
//  XMPPPushNotifications.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 04/04/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XMPPPushNotificationsEnvironment) {
    XMPPPushNotificationsEnvironmentProduction,
    XMPPPushNotificationsEnvironmentSandbox
};

@interface XMPPPushNotifications : XMPPModule

@property (strong, readonly) XMPPJID *pubSubServiceJid;
@property (strong, readonly) NSString *nodeName;

- (instancetype)initWithDispatchQueue:(nullable dispatch_queue_t)queue
                     pubSubServiceJid:(XMPPJID *)pubSubServiceJid
                             nodeName:(NSString *)nodeName
                          environment:(XMPPPushNotificationsEnvironment)environment NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPubSubServiceJid:(XMPPJID *)pubSubServiceJid
                                nodeName:(NSString *)nodeName
                             environment:(XMPPPushNotificationsEnvironment)environment;
- (id)init NS_UNAVAILABLE;

- (void)enableWithDeviceTokenString:(NSString *)deviceTokenString;
- (void)disable;

@end

@protocol XMPPPushNotificationsDelegate

@optional

- (void)xmppPushNotificationsDidEnable:(XMPPPushNotifications *)sender;
- (void)xmppPushNotificationsDidDisable:(XMPPPushNotifications *)sender;
- (void)xmppPushNotifications:(XMPPPushNotifications *)sender didFailToEnableWithErrorResult:(XMPPIQ *)errorResult;
- (void)xmppPushNotifications:(XMPPPushNotifications *)sender didFailToDisableWithErrorResult:(XMPPIQ *)errorResult;

@end

NS_ASSUME_NONNULL_END
