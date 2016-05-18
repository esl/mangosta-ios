//
//  XMPPMUCLight.h
//  Mangosta
//
//  Created by Andres Canal on 4/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPRoom.h>

@interface XMPPMUCLight : XMPPRoom

- (void)leaveMUCLightRoom:(XMPPJID *)userJID;
- (void)addUsers:(NSArray *)users;
- (void)setMyRoomJID:(XMPPJID*)userJID;
- (void)setRoomSubject:(NSString*)subject;
- (void)fetchAllMembersList;
- (void)sendMessageWithBody:(NSString *)text;
- (void)createMUCLightRoom:(NSString *)roomName members:(NSArray *) members;
@end

@protocol XMPPMUCLightDelegate<XMPPRoomDelegate>
@optional

- (void)xmppRoom:(XMPPMUCLight *)sender didLeftMUCLightRoom:(XMPPIQ*) iqResult;
- (void)xmppRoom:(XMPPMUCLight *)sender didFailToLeaveMUCLightRoom:(XMPPIQ*) iqResult;

- (void)xmppRoom:(XMPPMUCLight *)sender didAddUsers:(XMPPIQ*) iqResult;
- (void)xmppRoom:(XMPPMUCLight *)sender didFailToAddUsers:(XMPPIQ*) iqResult;

- (void)xmppRoom:(XMPPMUCLight *)sender didCreateMUCLightRoom:(XMPPIQ *)iq;
- (void)xmppRoom:(XMPPMUCLight *)sender didFailToCreateMUCLightRoom:(XMPPIQ *)iq;

- (void)xmppRoom:(XMPPMUCLight *)sender didFetchedAllMembers:(XMPPIQ *)iq;
- (void)xmppRoom:(XMPPMUCLight *)sender didFailToFetchAllMembers:(XMPPIQ *)iq;

@end

