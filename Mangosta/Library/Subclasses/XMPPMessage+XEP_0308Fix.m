//
//  XMPPMessage+XEP_0308Fix.m
//  Mangosta
//
//  Created by Sergio Abraham on 2/24/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPMessage+XEP_0308Fix.h"

@implementation XMPPMessage (XEP_0308Fix)

- (XMPPMessage *)generateCorrectionMessageWithID:(NSString *)elementID body:(NSString *)body
{
    XMPPMessage *correctionMessage = nil;
    
    if([[self elementID] length] && ![self isMessageCorrection])
    {
        correctionMessage = [self copy];
        
        [correctionMessage removeAttributeForName:@"id"];
        
        if([elementID length])
        {
            [correctionMessage addAttributeWithName:@"id" stringValue:elementID];
        }
        
        NSXMLElement *bodyElement = [correctionMessage elementForName:@"body"];
        
        if(bodyElement)
        {
            [correctionMessage removeChildAtIndex:[[correctionMessage children] indexOfObject:bodyElement]];
        }
        
        [correctionMessage addBody:body];
        
        [correctionMessage addMessageCorrectionWithID:[self elementID]];
    }
    
    return correctionMessage;
}

@end
