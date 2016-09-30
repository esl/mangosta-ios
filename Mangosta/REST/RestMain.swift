//
//  RestMain.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class MIMMainInterface: MIMCommunicable {
	
	// MARK: ChatViewController
	func sendMessage(xmppMessage: XMPPMessage) {
		let message = Message(id: NSUUID().UUIDString, to: xmppMessage.to().bare(), body: xmppMessage.body())
		MessageRepository().sendMessage(message).start() { result in
			switch result {
			case .Success(let messageSent):
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func getMessages() {
		MessageRepository().getNMessages("", before: "").start() {
			result in
			switch result {
			case .Success(let messageList):
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPRoom) {
		let room = Room(id: room.roomJID.bare(), subject: room.roomSubject, name: invitationMessage)
		RoomRepository().addUserToRoom(room, userJID: jid.bare()).start() {
			result in
			switch result {
			case .Success(let userInvited):
				
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func retrieveMessageArchiveWithFields(fields: [AnyObject]!, withResultSet resultSet: XMPPResultSet!) { // func fetchHistory()
		
	}
	
	func getRooms() -> [Room] {
		var r: [Room] = []
		RoomRepository().findAll().start() {
			result in
			switch result {
			case .Success(let users):
				r = users
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return r
	}
	
	// MARK: MainViewController
	func addUser(jid: XMPPJID!, withNickname optionalName: String!) {
		
	}
	
	func createRoomWithSubject(room: XMPPRoom, users: [XMPPJID]?) { // MUCRoomCreateViewController
		let roomToCreate = Room(id: room.roomJID.bare(), subject: room.roomSubject, name: room.roomJID.bare()) // FIXME: what is room name here?
		RoomRepository().create(roomToCreate).start() {
			result in
			switch result {
			case .Success(let roomCreated):
				// TODO: save id
				print("roomCreated")
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID) {
		let thisRoom = Room(id: room.roomJID.bare(), subject: room.roomSubject, name: "")
		RoomRepository().deleteUserFromRoom(thisRoom, userJID: user.bare()).start() {
			result in
			switch result {
			case .Success(let userDeleted):
				print("userDeleted")
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func getRoomArchivedMessages(room: XMPPRoom, limit: String, before: String) {
		let thisRoom = Room(id: room.roomJID.bare(), subject: room.roomSubject, name: "")
		RoomRepository().getMessagesFromRoom(thisRoom.id, limit: limit, before: before).start() {
			result in
			switch result {
			case .Success(let messageList):
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage) {
		let thisRoom = Room(id: room.roomJID.bare(), subject: room.roomSubject, name: "")
		RoomRepository().sendMessageToRoom(thisRoom, messageBody: message.body()).start() {
			result in
			switch result {
			case .Success(let messageSent):
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
}
