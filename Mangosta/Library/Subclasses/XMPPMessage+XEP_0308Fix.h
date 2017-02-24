//
//  XMPPMessage+XEP_0308Fix.h
//  Mangosta
//
//  Created by Sergio Abraham on 2/24/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework/XMPPMessage+XEP_0308.h"

@interface XMPPMessage (XEP_0308Fix)

- (XMPPMessage *)generateCorrectionMessageWithID:(NSString *)elementID body:(NSString *)body;

@end
