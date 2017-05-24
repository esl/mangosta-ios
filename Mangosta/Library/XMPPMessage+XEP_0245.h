//
//  XMPPMessage+XEP_0245.h
//
//  Created by Sergio Abraham on 9/9/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPMessage (XEP_0245)

- (XMPPJID *)meCommandSubstitutionUserJID;
- (NSString *)meCommandDefaultSubstitution;

@end
