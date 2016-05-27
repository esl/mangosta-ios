//
//  XMPPMUCLight.h
//  Mangosta
//
//  Created by Andres Canal on 4/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPRoom.h>

@interface XMPPMUCLight : XMPPRoom

- (void)kleaveMUCLightRoom:(XMPPJID *)userJID;
- (void)kaddUsers:(NSArray *)users;
- (void)ksetMyRoomJID:(XMPPJID*)userJID;
- (void)ksetRoomSubject:(NSString*)subject;
- (void)kfetchAllMembersList;
- (void)ksendMessageWithBody:(NSString *)text;
- (void)kcreateMUCLightRoom:(NSString *)roomName members:(NSArray *) members;
@end

@protocol kXMPPMUCLightDelegate<XMPPRoomDelegate>
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

