//
//  XMPPMessageArchivingCoreDataStorage+XEP_0066.h
//  Mangosta
//
//  Created by Piotrek on 08/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPMessageArchivingCoreDataStorage (XEP_0066)

@property (assign, nonatomic, getter=isOutOfBandMessageArchivingEnabled) BOOL outOfBandMessageArchivingEnabled;

@end
