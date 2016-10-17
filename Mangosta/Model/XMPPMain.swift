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
	
	func getMessages(limit: Int?, before: CLong?) {}
	func sendMessage(xmppMessage: XMPPMessage) {
		self.xmppController.xmppStream.sendElement(xmppMessage)
	}
	
	func getMessagesWithUser(user: XMPPJID, limit: Int?, before: CLong?) -> [XMPPMessage] {
		// TODO: self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
		return []
	}
	func getRooms() -> [XMPPRoom]{return [] }
	func getRoomArchivedMessages(room: XMPPRoom, limit: Int?, before: CLong?) -> [XMPPRoom]  {return [] }  // Not implemented func fetchHistory()

	
	func createRoomWithSubject(room: XMPPCustomRoomLight, name: String, subject: String, users: [XMPPJID]?) {
		// NOTE: name, subjet and user not used in xmpp implementation of this method.
		room.createRoomLightWithMembersJID(users)
	}
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPCustomRoomLight) {}
	
	func getRoomDetails(room: XMPPRoom) -> [String:AnyObject]{return [:]} // func showMUCDetails()
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID) {}
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage) {
		// TODO: self.xmppController.xmppStream.sendElement(msg)
	}
}