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
	
	func getMessages(_ limit: Int?, before: CLong?)
	func sendMessage(_ xmppMessage: XMPPMessage)
	
	#if MangostaREST
	func getMessagesWithUser(user: XMPPJID, limit: Int?, before: CLong?) -> [Message]
	func getRooms() -> [Room]
	func getRoomArchivedMessages(room: XMPPRoom, limit: Int?, before: CLong?) -> [Message]
	func getRoomDetails(room: XMPPRoom) -> Room // func showMUCDetails()
	#else
	func getMessagesWithUser(_ user: XMPPJID, limit: Int?, before: CLong?) -> [XMPPMessage]
	func getRooms() -> [XMPPRoom]
	func getRoomArchivedMessages(_ room: XMPPRoom, limit: Int?, before: CLong?) -> [XMPPRoom]
	func getRoomDetails(_ room: XMPPRoom) -> [String:AnyObject] // func showMUCDetails()
	#endif
	
	func createRoomWithSubject(_ room: XMPPCustomRoomLight, name: String, subject: String, users: [XMPPJID]?)
	func inviteUserToRoom(_ jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPCustomRoomLight)
	func deleteUserFromRoom(_ room: XMPPRoom, user: XMPPJID)
	func sendMessageToRoom(_ room: XMPPRoom, message: XMPPMessage)
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
