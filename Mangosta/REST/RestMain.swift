//
//  RestMain.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class RestMain : MIMCommunicable {
	
	// MARK: ChatViewController
	func sendMessage(xmppMessage: XMPPMessage) {
		
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
		RoomRepository().findAll().start() { result in
			switch result {
			case .Success(let users): break
			// You've got all your users fetched in this array!
			case .Failure(let error): break
				// You've got a discrete JaymeError indicating what happened
			}
		}
		return []
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