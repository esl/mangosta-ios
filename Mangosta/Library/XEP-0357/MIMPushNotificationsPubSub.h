//
//  MIMPushNotificationsPubSub.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 21/04/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPPubSub.h>

@interface MIMPushNotificationsPubSub : XMPPPubSub

/// Overridden to include `type="push"` attribute (MongooseIM-specific requirement).
- (NSString *)createNode:(NSString *)aNode withOptions:(NSDictionary *)options;

@end
