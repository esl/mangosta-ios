//
//  XMPPRoomOperation.swfit
//  Mangosta
//
//  Created by Tom Ryan on 4/15/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class XMPPRoomOperation: AsyncOperation, XMPPRoomDelegate, XMPPStreamDelegate, XMPPRoomExtraActionsDelegate {
	var room: XMPPRoom?
	var mainOperation: ((room: XMPPRoom) -> ())?
	var completion: ((result: Bool, room: XMPPRoom) -> ())?
	var boolCompletion: ((result: Bool) -> ())?

	var fetchConfigurationCompletion: ((result: Bool, name: String) -> ())?
	var roomJID: XMPPJID?
	let domain = "muc.erlang-solutions.com"
	var roomName = ""
	var joinRoomFlag = false

	init(_ muc: XMPPRoom? = nil) {
		self.room = muc
	}
	
	override func execute() {
		var roomJID = XMPPJID.jidWithUser(XMPPStream.generateUUID(), domain: self.domain, resource: nil)
		if let theJid = self.roomJID {
			roomJID = theJid
		}
		if let xmppRoom = self.room where xmppRoom.xmppStream == nil {
			xmppRoom.activate(StreamManager.manager.stream)
		} else if self.room == nil {
			self.room = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: roomJID, dispatchQueue: dispatch_get_main_queue())
			self.room?.activate(StreamManager.manager.stream)
		}
		
		self.room?.xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.room?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		self.mainOperation?(room: self.room!)
	}
	
	internal func finishAndRemoveDelegates() {
		self.room?.removeDelegate(self)
		finish()
	}

	class func createRoom(name name: String, completion: (result: Bool, room: XMPPRoom) -> ()) -> XMPPRoomOperation {
		let createRoomOperation = XMPPRoomOperation()
		createRoomOperation.roomName = name
		createRoomOperation.mainOperation = { (room: XMPPRoom) -> () in
			room.joinRoomUsingNickname(XMPPStream.generateUUID(), history: nil)
		}
		createRoomOperation.completion = completion

		return createRoomOperation
	}
	
	class func invite(room room: XMPPRoom, userJIDs: [XMPPJID], completion: (result: Bool, room: XMPPRoom) -> ()) -> XMPPRoomOperation {
		let operation = XMPPRoomOperation(room)
		operation.mainOperation = { [unowned operation] (room: XMPPRoom) in
			for jid in userJIDs {
				room.inviteUser(jid, withMessage: room.roomSubject)
			}

			dispatch_async(dispatch_get_main_queue()) {
				operation.completion!(result: true, room: room)
			}

			operation.finishAndRemoveDelegates()
		}
		operation.completion = completion
		
		return operation
	}
	
	class func leave(room room: XMPPRoom, completion: (result: Bool) -> ()) -> XMPPRoomOperation {
		let operation = XMPPRoomOperation(room)
		operation.mainOperation = { (room: XMPPRoom) in
			room.changeAffiliation(room.xmppStream.myJID, affiliation: "none")
		}
		operation.boolCompletion = completion
		
		return operation
	}
	
	class func joinRoom(room: XMPPRoom, completion: (result: Bool, room: XMPPRoom) -> ()) -> XMPPRoomOperation {
		let joinRoomOperation = XMPPRoomOperation(room)
		joinRoomOperation.joinRoomFlag = true
		joinRoomOperation.mainOperation = { (room: XMPPRoom) -> () in
			room.joinRoomUsingNickname(room.xmppStream.myJID.user, history: nil)
		}
		joinRoomOperation.completion = completion
		
		return joinRoomOperation
	}
	
	//MARK: Change Affiliation
	func xmppRoom(sender: XMPPRoom!, didChangeAffiliationTo occupantJID: XMPPJID!) {
		self.boolCompletion?(result: true)
		self.finishAndRemoveDelegates()
	}

	func xmppRoom(sender: XMPPRoom!, didFailToChangeAffiliationTo occupantJID: XMPPJID!) {
		self.boolCompletion?(result: false)
		self.finishAndRemoveDelegates()
	}

	//MARK: Join Room
	func xmppRoomDidJoin(sender: XMPPRoom!) {
		if !self.joinRoomFlag {
			return
		}

		self.completion!(result: true, room: sender)
		self.finishAndRemoveDelegates()
	}
	
	func xmppRoomDidLeave(sender: XMPPRoom!) {
		self.boolCompletion!(result: false)
		self.finishAndRemoveDelegates()
	}

	//MARK: Create delegate
	func xmppRoomDidCreate(sender: XMPPRoom!) {
		let xElement = NSXMLElement(name: "x", xmlns: "jabber:x:data")
		xElement.addAttributeWithName("type", stringValue: "submit")

		xElement.addChild(self.configuration("muc#roomconfig_roomname", configValue: self.roomName))
		xElement.addChild(self.configuration("muc#roomconfig_persistentroom", configValue: "1"))
		
		sender.configureRoomUsingOptions(xElement)
		self.completion!(result: true, room: sender)
		self.finishAndRemoveDelegates()
	}
	
	private func configuration(name: String, configValue: String) -> NSXMLElement {
		let value = NSXMLElement(name: "value")
		value.setStringValue(configValue)
		
		let field = NSXMLElement(name: "field")
		field.addAttributeWithName("var", stringValue: name)
		field.addChild(value)
		
		return field
	}
	
	//MARK: Presence delegates
	
	func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
		let from = presence.from()
		
		if (!self.room!.roomJID.isEqualToJID(from, options: XMPPJIDCompareBare)) {
			return
		}
		
		if((presence.elementForName("error")) != nil) {
			completion!(result: false, room: room!)
			self.finishAndRemoveDelegates()
		}
	}

	//MARK: Configuration delegates
	func xmppRoom(sender: XMPPRoom!, didConfigure iqResult: XMPPIQ!) {
		completion!(result: true, room: sender)
		self.finishAndRemoveDelegates()
	}
	
	func xmppRoom(sender: XMPPRoom!, didNotConfigure iqResult: XMPPIQ!) {
		completion!(result: false, room: sender)
		self.finishAndRemoveDelegates()
	}
}