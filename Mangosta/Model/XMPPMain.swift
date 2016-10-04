//
//  XMPPMain.swift
//  Mangosta
//
//  Created by Sergio Abraham on 9/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class MIMMainInterface: MIMCommunicable {
	
	// MARK: ChatViewController
	func sendMessage(xmppMessage: XMPPMessage) {
		// TODO: self.xmppController.xmppStream.sendElement(msg)
	}
	func getMessages() {}
	// func inviteUser(jid: XMPPJID!, withMessage invitationMessage: String!)
	// func addUsers(users: [XMPPJID])
	// func showMUCDetails()
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPRoom) {}
	func retrieveMessageArchiveWithFields(fields: [AnyObject]!, withResultSet resultSet: XMPPResultSet!) {} // func fetchHistory()
	func getRooms() -> [XMPPRoom] {return [] }
	
	// MARK: MainViewController
	func addUser(jid: XMPPJID!, withNickname optionalName: String!) {}
	
	// MARK: MUCRoom
	// func joinRoomUsingNickname(desiredNickname: String!, history: DDXMLElement!) // createRoom
	func createRoomWithSubject(room: XMPPRoom, users: [XMPPJID]?) {}
	// func createRoom(roomName: String, users: [XMPPJID]?) // MUCRoomCreateViewController
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID) {}
	
	// MARK: MUCLightRoom
	// func createRoomLightWithMembersJID(members: [XMPPJID]?)
	
	func getRoomArchivedMessages(room: XMPPRoom, limit: String, before: String) {}
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage) {
		// TODO: self.xmppController.xmppStream.sendElement(msg)
	}
}