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

	var xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController
	
	func getMessages() {}
	func sendMessage(xmppMessage: XMPPMessage) {
		self.xmppController.xmppStream.sendElement(xmppMessage)
	}
	
	func getMessagesWithUser(user: XMPPJID, limit: Int, before: CLong) -> [XMPPMessage] {
		// TODO: self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
		return []
	}
	func getRooms() -> [XMPPRoom] {return [] }
	func getRoomArchivedMessages(room: XMPPRoom, limit: String, before: String) -> [XMPPRoom] {return []}
	
	func createRoomWithSubject(room: XMPPRoom, users: [XMPPJID]?) {}
	func getRoomDetails(room: XMPPRoom) -> [String:AnyObject] {return [:]} // func showMUCDetails()
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPRoom) {}
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID) {}
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage) {
		// TODO: self.xmppController.xmppStream.sendElement(msg)
	}
	
	//func retrieveMessageArchiveWithFields(fields: [AnyObject]!, withResultSet resultSet: XMPPResultSet!) {} // func fetchHistory()
	//func addUser(jid: XMPPJID!, withNickname optionalName: String!) {}
	// func inviteUser(jid: XMPPJID!, withMessage invitationMessage: String!)
	// func addUsers(users: [XMPPJID])
	// func showMUCDetails()
	// MARK: MUCLightRoom
	// func createRoomLightWithMembersJID(members: [XMPPJID]?)
	// MARK: MUCRoom
	// func joinRoomUsingNickname(desiredNickname: String!, history: DDXMLElement!) // createRoom
	// func createRoom(roomName: String, users: [XMPPJID]?) // MUCRoomCreateViewController
	// MARK: MainViewController
}