//
//  XMPPSlot.m
//  Mangosta
//
//  Created by Andres Canal on 5/19/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPSlot.h"

@implementation XMPPSlot

- (id)initWithGet:(NSString *)put andGet:(NSString *)get {
	
	self = [super init];
	if(self) {
		get = get;
		put = put;
	}
	return self;

}

@end
