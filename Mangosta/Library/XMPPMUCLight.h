//
//  XMPPMUCLight.h
//  Mangosta
//
//  Created by Andres Canal on 4/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPRoom.h"

@interface XMPPMUCLight : XMPPRoom

- (void)leaveMUCLightRoom:(XMPPJID *)userJID;
- (void)addUsers:(NSArray *)users;
- (void)setMyRoomJID:(XMPPJID*)userJID;
- (void)setRoomSubject:(NSString*)subject;
- (void)fetchAllMembersList;
- (void)sendMessageWithBody:(NSString *)text;

@end

@protocol XMPPMUCLightDelegate<XMPPRoomDelegate>
@optional

- (void)xmppRoom:(XMPPMUCLight *)sender didLeaveMUCLightRoom:(XMPPIQ*) iqResult;
- (void)xmppRoom:(XMPPMUCLight *)sender didNotLeaveMUCLightRoom:(XMPPIQ*) iqResult;

- (void)xmppRoom:(XMPPMUCLight *)sender didAddUsers:(XMPPIQ*) iqResult;
- (void)xmppRoom:(XMPPMUCLight *)sender didNotAddUsers:(XMPPIQ*) iqResult;

- (void)xmppRoom:(XMPPMUCLight *)sender didSendMessage:(XMPPMessage*) message;
- (void)xmppRoom:(XMPPMUCLight *)sender didFailToSendMessage:(XMPPMessage*) message;

@end

