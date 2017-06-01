//
//  XMPPStream+XEP_0245.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPStream (XEP_0245)

- (NSString *)meCommandSubstitutionStringForMessage:(XMPPMessage *)message;

@end
