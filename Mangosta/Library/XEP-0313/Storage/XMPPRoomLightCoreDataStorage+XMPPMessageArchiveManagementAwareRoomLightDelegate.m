//
//  XMPPRoomLightCoreDataStorage+XMPPMessageArchiveManagementAwareRoomLightDelegate.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRoomLightCoreDataStorage+XMPPMessageArchiveManagementAwareRoomLightDelegate.h"

@implementation XMPPRoomLightCoreDataStorage (XMPPMessageArchiveManagementAwareRoomLightDelegate)

- (void)xmppRoomLight:(XMPPRoomLight *)sender didReceiveArchivedMessage:(XMPPMessage *)message withTimestamp:(NSDate *)timestamp
{
    [self importRemoteArchiveMessage:message withTimestamp:timestamp inRoom:sender fromStream:sender.xmppStream];
}

@end
