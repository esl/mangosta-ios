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

	var xmppController = XMPPController.sharedInstance
	
	func getMessages(_ limit: Int?, before: CLong?) {}
	func sendMessage(_ xmppMessage: XMPPMessage) {
		self.xmppController.xmppStream.send(xmppMessage)
	}
	
	func getMessagesWithUser(_ user: XMPPJID, limit: Int?, before: CLong?) -> [XMPPMessage] {
		// TODO: self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
		return []
	}
	func getRooms() -> [XMPPRoom] {return [] }
	func getRoomArchivedMessages(_ room: XMPPRoom, limit: Int?, before: CLong?) -> [XMPPRoom] {return [] }  // Not implemented func fetchHistory()

	
	func createRoomWithSubject(_ room: XMPPRoomLight, name: String, subject: String, users: [XMPPJID]?) {
		// NOTE: name, subjet and user not used in xmpp implementation of this method.
		room.createRoomLight(withMembersJID: users)
	}
	func inviteUserToRoom(_ jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPRoomLight) {}
	
	func getRoomDetails(_ room: XMPPRoom) -> [String:AnyObject] {return [:] } // func showMUCDetails()
	func deleteUserFromRoom(_ room: XMPPRoom, user: XMPPJID) {}
	func sendMessageToRoom(_ room: XMPPRoom, message: XMPPMessage) {
		// TODO: self.xmppController.xmppStream.sendElement(msg)
	}
}
