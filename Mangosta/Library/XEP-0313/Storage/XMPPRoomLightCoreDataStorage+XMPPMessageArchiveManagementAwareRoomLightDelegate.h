//
//  XMPPRoomLightCoreDataStorage+XMPPMessageArchiveManagementAwareRoomLightDelegate.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPRoomLight+XEP_0313.h"

@interface XMPPRoomLightCoreDataStorage (XMPPMessageArchiveManagementAwareRoomLightDelegate) <XMPPMessageArchiveManagementAwareRoomLightDelegate>

- (void)xmppRoomLight:(XMPPRoomLight *)sender didReceiveArchivedMessage:(XMPPMessage *)message withTimestamp:(NSDate *)timestamp;

@end
