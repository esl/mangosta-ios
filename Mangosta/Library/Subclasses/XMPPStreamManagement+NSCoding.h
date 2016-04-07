//
//  XMPPStreamManagement+NSCoding.h
//  Mangosta
//
//  Created by Tom Ryan on 4/7/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPStreamManagement.h>

@interface XMPPStreamManagement (NSCoding)

- (void)saveState;
- (void)loadState;
- (void)deleteState;
@end
