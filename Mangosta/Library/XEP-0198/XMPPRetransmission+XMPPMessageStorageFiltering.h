//
//  XMPPRetransmission+XMPPMessageStorageFiltering.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRetransmission.h"

@interface XMPPRetransmission (XMPPMessageStorageFiltering)

- (BOOL)isRetransmittingElement:(XMPPElement *)element;

@end
