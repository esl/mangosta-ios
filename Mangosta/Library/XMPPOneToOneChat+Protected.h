//
//  XMPPOneToOneChat+Protected.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOneToOneChat.h"

@interface XMPPOneToOneChat (Protected)

- (void)handleMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing inStream:(XMPPStream *)stream;

@end
