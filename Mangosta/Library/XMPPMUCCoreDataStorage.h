//
//  XMPPMUCCoreDataStorage.h
//  Mangosta
//
//  Created by Andres Canal on 5/4/16.
//  Copyright © 2016 Inaka. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <XMPPFramework/XMPPFramework.h>
#import <XMPPFramework/XMPPCoreDataStorage.h>

@interface XMPPMUCCoreDataStorage : XMPPCoreDataStorage

- (void)handleIncomingMessage:(XMPPMessage *)message stream:(XMPPStream *) stream;
- (void)handleOutgoingMessage:(XMPPMessage *)message stream:(XMPPStream *)stream;

@end
