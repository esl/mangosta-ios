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
	
	// MARK: ChatViewController
	func sendMessage(xmppMessage: XMPPMessage)
	func getMessages()
	
	func getMessagesWithUser(user: XMPPJID, limit: Int , before: CLong?) -> [XMPPMessage]
	// TODO: to implement
	// func inviteUser(jid: XMPPJID!, withMessage invitationMessage: String!)
	// func addUsers(users: [XMPPJID])
	// func showMUCDetails()
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPRoom)
	func retrieveMessageArchiveWithFields(fields: [AnyObject]!, withResultSet resultSet: XMPPResultSet!) // func fetchHistory()
	#if MangostaREST
	func getRooms() -> [Room]
	#else
	func getRooms() -> [XMPPRoom]
	#endif
	// MARK: MainViewController
	func addUser(jid: XMPPJID!, withNickname optionalName: String!)
	
	// MARK: MUCRoom
	// func joinRoomUsingNickname(desiredNickname: String!, history: DDXMLElement!) // createRoom
	func createRoomWithSubject(room: XMPPRoom, users: [XMPPJID]?)
	// func createRoom(roomName: String, users: [XMPPJID]?) // MUCRoomCreateViewController
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID)
	
	// MARK: MUCLightRoom
	// TODO: to implement
	// func createRoomLightWithMembersJID(members: [XMPPJID]?)
	
	func getRoomArchivedMessages(room: XMPPRoom, limit: String, before: String)
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage)
	
	// MARK: Blocking
	// TODO: to implement
	// func blockJID(xmppJID: XMPPJID!)
	// func unblockJID(xmppJID: XMPPJID!)
	
}