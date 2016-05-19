//
//  XMPPSlot.h
//  Mangosta
//
//  Created by Andres Canal on 5/19/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPJID.h"

@import KissXML;

@interface XMPPSlot : NSXMLElement

- (id)initWithGet:(NSString *)put andGet:(NSString *)get;

@property (nonatomic, strong, readonly) NSString *put;
@property (nonatomic, strong, readonly) NSString *get;

@end
