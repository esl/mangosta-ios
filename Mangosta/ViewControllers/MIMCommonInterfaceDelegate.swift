//
//  MIMCommonInterfaceDelegate.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

protocol MIMCommunicable {
	
	func getMessages(limit: Int?, before: CLong?)
	func sendMessage(xmppMessage: XMPPMessage)
	
	#if MangostaREST
	func getMessagesWithUser(user: XMPPJID, limit: Int?, before: CLong?) -> [Message]
	func getRooms() -> [Room]
	func getRoomArchivedMessages(room: XMPPRoom, limit: Int?, before: CLong?) -> [Message]
	func getRoomDetails(room: XMPPRoom) -> Room // func showMUCDetails()
	#else
	func getMessagesWithUser(user: XMPPJID, limit: Int?, before: CLong?) -> [XMPPMessage]
	func getRooms() -> [XMPPRoom]
	func getRoomArchivedMessages(room: XMPPRoom, limit: Int?, before: CLong?) -> [XMPPRoom]
	func getRoomDetails(room: XMPPRoom) -> [String:AnyObject] // func showMUCDetails()
	#endif
	
	func createRoomWithSubject(room: XMPPCustomRoomLight, name: String, subject: String, users: [XMPPJID]?)
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPCustomRoomLight)
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID)
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage)
	 	// func inviteUser(jid: XMPPJID!, withMessage invitationMessage: String!)
	// func addUsers(users: [XMPPJID])
	// MARK: MainViewController
	// func addUser(jid: XMPPJID!, withNickname optionalName: String!)
	
	// MARK: MUCRoom
	// func joinRoomUsingNickname(desiredNickname: String!, history: DDXMLElement!) // createRoom
	// func createRoom(roomName: String, users: [XMPPJID]?) // MUCRoomCreateViewController
	
	// MARK: MUCLightRoom
	// TODO: to implement
	// func createRoomLightWithMembersJID(members: [XMPPJID]?)
	
	
	// MARK: Blocking
	// TODO: to implement
	// func blockJID(xmppJID: XMPPJID!)
	// func unblockJID(xmppJID: XMPPJID!)
	
}