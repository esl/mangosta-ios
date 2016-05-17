//
//  XMPPMessageAndMAMArchivingCoreDataStorage.h
//  Mangosta
//
//  Created by Andres Canal on 5/17/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import <XMPPFramework/XMPPMessageArchivingCoreDataStorage.h>

@interface XMPPMessageAndMAMArchivingCoreDataStorage : XMPPMessageArchivingCoreDataStorage

- (void)archiveMAMMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)xmppStream;

@end
