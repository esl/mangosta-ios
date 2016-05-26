//
//  XMPPSlot.h
//  Mangosta
//
//  Created by Andres Canal on 5/19/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPJID.h"
#import "XMPPIQ.h"

@import KissXML;

@interface XMPPSlot : NSXMLElement

- (id)initWithPut:(NSString *)put get:(NSString *)get;
- (id)initWithIQ:(XMPPIQ *)iq;

@property (nonatomic, strong, readonly) NSString *put;
@property (nonatomic, strong, readonly) NSString *get;

@end
