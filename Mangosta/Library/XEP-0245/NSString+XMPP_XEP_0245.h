//
//  NSString+XMPP_XEP_0245.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 24/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (XMPP_XEP_0245)

- (BOOL)hasXMPPMeCommandPrefix;
- (NSString *)xmppMessageBodyStringByTrimmingMeCommand;

@end
