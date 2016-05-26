//
//  XMPPMUCStorer.h
//  Mangosta
//
//  Created by Andres Canal on 5/3/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import "XMPPMUCCoreDataStorage.h"

@interface XMPPMUCStorer : XMPPModule {
	
}

- (id)initWithRoomStorage:(XMPPMUCCoreDataStorage *)storage;

@property (readonly) XMPPMUCCoreDataStorage* xmppMUCStorage;

@end
