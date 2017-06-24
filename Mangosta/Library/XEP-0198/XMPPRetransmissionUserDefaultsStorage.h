//
//  XMPPRetransmissionUserDefaultsStorage.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRetransmission.h"

@interface XMPPRetransmissionUserDefaultsStorage : NSObject <XMPPRetransmissionStorage>

- (instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

@end
