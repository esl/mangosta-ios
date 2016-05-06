//
//  XMPPRoom+ExtraActions.h
//  Mangosta
//
//  Created by Andres Canal on 5/6/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>
#import <XMPPFramework/XMPPRoom.h>
#import <XMPPFramework/XMPPIDTracker.h>

@interface XMPPRoom (ExtraActions)

- (void)changeAffiliation:(XMPPJID *)userJID affiliation:(NSString *) affiliation;

@end

@protocol XMPPRoomExtraActionsDelegate <XMPPRoomDelegate>
@optional

- (void)xmppRoom:(XMPPRoom *)sender didChangeAffiliationTo:(XMPPJID *)occupantJID;
- (void)xmppRoom:(XMPPRoom *)sender didFailToChangeAffiliationTo:(XMPPJID *)occupantJID;

@end
