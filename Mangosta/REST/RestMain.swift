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
	
	func getMessages(_ limit: Int?, before: CLong?) {
		MessageRepository().getNMessages(nil, before: nil).start() {
			result in
			switch result {
			case .success(let messageList):
				print("DEBUG MessageList \(messageList)")
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func sendMessage(_ xmppMessage: XMPPMessage) {
		let message = Message(id: UUID().uuidString, to: xmppMessage.to().bare(), from: "", body: xmppMessage.body(), timestamp: NSNotFound)
		MessageRepository().sendMessage(message).start() { result in
			switch result {
			case .success( _):
				
				XMPPController.sharedInstance.xmppMessageArchivingStorage.archiveMessage(xmppMessage, outgoing: true, xmppStream: XMPPController.sharedInstance.xmppStream)
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func getMessagesWithUser(user: XMPPJID, limit: Int?, before: CLong?) -> [Message] {
		var returnist : [Message] = []
		
		MessageRepository().getNMessagesWithUser(user.bare(), limit: limit as NSNumber?, before: before as NSNumber?).start() {
			result in
			switch result {
			case .success(let messageList):
				returnist = messageList
				print ("Message list \(messageList)")
				// Using xmpp method for retrieval until sse is completed.
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
		
		return returnist
	}
	
	func getRooms() -> [Room] {
		var roomList: [Room] = []
		RoomRepository().findAll().start() {
			result in
			switch result {
			case .success(let rooms):
				print ("DEBUG room list \(rooms)")
				roomList = rooms
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return roomList
	}
	
	func getRoomArchivedMessages(room: XMPPRoom, limit: Int?, before: CLong?) -> [Message] {
		var messages: [Message] = []
		let dictionary  : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.roomSubject as AnyObject, "name": "" as AnyObject]
		let thisRoom = try? Room(dictionary: dictionary)
		RoomRepository().getMessagesFromRoom(thisRoom!.id, limit: limit as NSNumber?, before: before as NSNumber?).start() {
			result in
			switch result {
			case .success(let archivedList):
				print ("DEBUG archive message list \(archivedList)")
				messages = archivedList
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return messages
	}
	
	func createRoomWithSubject(_ room: XMPPCustomRoomLight, name: String, subject: String, users: [XMPPJID]?) {
		let roomToCreate = Room(id: "", subject: subject, name: name, participants: ["":""])
		RoomRepository().create(roomToCreate).start() {
			result in
			switch result {
			case .success(let roomCreated):
				// NOTE: The current API does not use sse, then the only way to manage incoming messages is to configure a XMPPRoomLight object from the id obtained.
				print("DEBUG roomCreated: \(roomCreated)")
				// We get the new id from the server. We recreate muclight room since we cannot assign it.
				let newRoomLight = XMPPCustomRoomLight(jid: room.roomJID, roomname: room.roomname())
				room.destroyRoom()
				newRoomLight.addDelegate(self, delegateQueue: DispatchQueue.main)
				
				// TODO: implement this here for MucLightfrom activate
				
				//		 	[responseTracker addID:iqID
				//				target:self
				//				selector:@selector(handleCreateRoomLight:withInfo:)
				//			timeout:60.0];

				if let users = users {
					users.forEach { (jid) in
						self.inviteUserToRoom(jid, withMessage: subject, room: newRoomLight)
					}
				}
				
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func getRoomDetails(room: XMPPRoom) -> Room {
		var detailsDictionary : Room = try! Room(dictionary: [:])
		RoomRepository().find(byId: room.roomJID.bare()).start() {
			result in
			switch result {
			case .success(let details):
				detailsDictionary = details
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return detailsDictionary
	}
	
	func inviteUserToRoom(_ jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPCustomRoomLight) {
		let dictionary : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.subject() as AnyObject, "name": "" as AnyObject]
		let room = try? Room(dictionary: dictionary)
		RoomRepository().addUserToRoom(room!, userJID: jid.bare()).start() {
			result in
			switch result {
			case .success(let userInvited):
				print("DEBUG userInvited: \(userInvited)")
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func deleteUserFromRoom(_ room: XMPPRoom, user: XMPPJID) {
		let dictionary : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.roomSubject as AnyObject, "name": "" as AnyObject]
		let thisRoom = try? Room(dictionary: dictionary)
		RoomRepository().deleteUserFromRoom(thisRoom!, userJID: user.bare()).start() {
			result in
			switch result {
			case .success(let userDeleted):
				print("DEBUG userDeleted: \(userDeleted)")
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func sendMessageToRoom(_ room: XMPPRoom, message: XMPPMessage) {
		let dictionary : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.roomSubject as AnyObject, "name": "" as AnyObject]
		let thisRoom = try? Room(dictionary: dictionary)
		RoomRepository().sendMessageToRoom(thisRoom!, messageBody: message.body()).start() {
			result in
			switch result {
			case .success(let messageSent):
				print("DEBUG: messageSent: \(messageSent)")
				break
			case .failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
}
