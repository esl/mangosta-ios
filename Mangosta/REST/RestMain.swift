//
//  RestMain.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class RestMain  {
	
	// MARK: ChatViewController
	func sendMessage(xmppMessage: XMPPMessage) {
		let message = Message(id: NSUUID().UUIDString, to: xmppMessage.to().bare(), body: xmppMessage.body())
		MessageRepository().create(message).start() { result in
			switch result {
			case .Success(let messageSent):
				break
			case .Failure(let error):
				// You've got a discrete JaymeError indicating what happened
				print("Error: \(error)")
				break
			}
	}
	}
	func inviteUser(jid: XMPPJID!, withMessage invitationMessage: String!) {
		
	}
	func addUsers(users: [XMPPJID]) {
		
	}
	func showMUCDetails() {
		
	}
	func retrieveMessageArchiveWithFields(fields: [AnyObject]!, withResultSet resultSet: XMPPResultSet!) { // func fetchHistory()
		
	}
	func getRooms() -> [Room] {
		var r : [Room] = []
		RoomRepository().findAll().start() { result in
			switch result {
			case .Success(let users):
				r = users
				break
			case .Failure(let error):
				// You've got a discrete JaymeError indicating what happened
				print("Error: \(error)")
				break
			}
		}
		return r
	}
	
	// MARK: MainViewController
	func addUser(jid: XMPPJID!, withNickname optionalName: String!) {
		
	}
	
	// MARK: MUCRoom
	func joinRoomUsingNickname(desiredNickname: String!, history: DDXMLElement!) { // createRoom
	}
	func createRoom(roomName: String, users: [XMPPJID]?) { // MUCRoomCreateViewController
	}
	
	// MARK: MUCLightRoom
	func createRoomLightWithMembersJID(members: [XMPPJID]?) {
		
	}
	
	// Blocking
	func blockJID(xmppJID: XMPPJID!) {
		
	}
	func unblockJID(xmppJID: XMPPJID!) {
		
	}

}
