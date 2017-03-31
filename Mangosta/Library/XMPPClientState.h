//
//  XMPPClientState.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 31/03/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPClientState : XMPPModule

@property (atomic, getter=isActive) BOOL active;

@end
