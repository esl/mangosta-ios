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
	
	func getMessages(limit: Int?, before: CLong?) {
		MessageRepository().getNMessages(nil, before: nil).start() {
			result in
			switch result {
			case .Success(let messageList):
				print("DEBUG MessageList \(messageList)")
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func sendMessage(xmppMessage: XMPPMessage) {
		let message = Message(id: NSUUID().UUIDString, to: xmppMessage.to().bare(), body: xmppMessage.body())
		MessageRepository().sendMessage(message).start() { result in
			switch result {
			case .Success(let messageSent):
				print("DEBUG Message sent \(messageSent))")
				var xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController
				let xmppMessage = xmppMessage(
				let arc = XMPPMessageArchivingCoreDataStorage().archiveMessage(xmppMessage, outgoing: true, xmppStream: xmppController.xmppStream)
					- (void)archiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)xmppStream
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func getMessagesWithUser(user: XMPPJID, limit: Int?, before: CLong?) -> [Message] {
		var returnist : [Message] = []
		
		MessageRepository().getNMessagesWithUser(user.bare(), limit: limit, before: before).start() {
			result in
			switch result {
			case .Success(let messageList):
				returnist = messageList
				print ("DEBUG message list \(messageList)")
				break
			case .Failure(let error):
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
			case .Success(let rooms):
				print ("DEBUG room list \(rooms)")
				roomList = rooms
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return roomList
	}
	
	func getRoomArchivedMessages(room: XMPPRoom, limit: Int?, before: CLong?) -> [Message] {
		var messages: [Message] = []
		let dictionary  : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.roomSubject, "name": ""]
		let thisRoom = try? Room(dictionary: dictionary)
		RoomRepository().getMessagesFromRoom(thisRoom!.id, limit: limit, before: before).start() {
			result in
			switch result {
			case .Success(let archivedList):
				print ("DEBUG archive message list \(archivedList)")
				messages = archivedList
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return messages
	}
	
	func createRoomWithSubject(room: XMPPCustomRoomLight, name: String, subject: String, users: [XMPPJID]?){
		let roomToCreate = Room(id: "", subject: subject, name: name, participants: ["":""])
		RoomRepository().create(roomToCreate).start() {
			result in
			switch result {
			case .Success(let roomCreated):
				// NOTE: The current API does not use sse, then the only way to manage incoming messages is to configure a XMPPRoomLight object from the id obtained.
				print("DEBUG roomCreated: \(roomCreated)")
				// We get the new id from the server. We recreate muclight room since we cannot assign it.
				let newRoomLight = XMPPCustomRoomLight(JID: room.roomJID, roomname: room.roomname())
				room.destroyRoom()
				newRoomLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())
				
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
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func getRoomDetails(room: XMPPRoom) -> Room {
		var detailsDictionary : Room = try! Room(dictionary: [:])
		RoomRepository().findByID(room.roomJID.bare()).start() {
			result in
			switch result {
			case .Success(let details):
				detailsDictionary = details
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
		return detailsDictionary
	}
	
	func inviteUserToRoom(jid: XMPPJID!, withMessage invitationMessage: String!, room: XMPPCustomRoomLight) {
		let dictionary : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.subject(), "name": ""]
		let room = try? Room(dictionary: dictionary)
		RoomRepository().addUserToRoom(room!, userJID: jid.bare()).start() {
			result in
			switch result {
			case .Success(let userInvited):
				print("DEBUG userInvited: \(userInvited)")
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func deleteUserFromRoom(room: XMPPRoom, user: XMPPJID) {
		let dictionary : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.roomSubject, "name": ""]
		let thisRoom = try? Room(dictionary: dictionary)
		RoomRepository().deleteUserFromRoom(thisRoom!, userJID: user.bare()).start() {
			result in
			switch result {
			case .Success(let userDeleted):
				print("DEBUG userDeleted: \(userDeleted)")
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
	func sendMessageToRoom(room: XMPPRoom, message: XMPPMessage) {
		let dictionary : [String:AnyObject] = ["id": room.roomJID.bare(), "subject":room.roomSubject, "name": ""]
		let thisRoom = try? Room(dictionary: dictionary)
		RoomRepository().sendMessageToRoom(thisRoom!, messageBody: message.body()).start() {
			result in
			switch result {
			case .Success(let messageSent):
				print("DEBUG: messageSent: \(messageSent)")
				break
			case .Failure(let error):
				print("Error: \(error)")
				break
			}
		}
	}
	
}
