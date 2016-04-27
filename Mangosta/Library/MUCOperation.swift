//
//  MUCOperation.swift
//  Mangosta
//
//  Created by Tom Ryan on 4/15/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class MUCOperation: AsyncOperation, XMPPMUCDelegate {
	var room: XMPPRoom?
	var mainOperation: ((room: XMPPRoom) -> ())?
	var completion: ((result: Bool, room: XMPPRoom) -> ())?
	var fetchConfigurationCompletion: ((result: Bool, name: String) -> ())?
	var domain: String?
	
	var roomJID: XMPPJID?
	
	init(_ muc: XMPPRoom? = nil) {
		self.room = muc
		
		if let auth = AuthenticationModel.load() {
			if let authDomain = auth.serverName {
				self.domain = "muc.\(authDomain)"
			}
		}
	}
	
	override func execute() {
		var roomJID = XMPPJID.jidWithUser(XMPPStream.generateUUID(), domain: self.domain, resource: nil)
		if let theJid = self.roomJID {
			roomJID = theJid
		}
		if let xmppRoom = self.room where xmppRoom.xmppStream == nil {
			xmppRoom.activate(StreamManager.manager.stream)
		} else if self.room == nil {
			let storage = StreamManager.manager.streamController?.roomStorage
			self.room = XMPPRoom(roomStorage: storage, jid: roomJID, dispatchQueue: dispatch_get_main_queue())
			self.room?.activate(StreamManager.manager.stream)
		}
		
		self.room?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		self.mainOperation?(room: self.room!)
	}
	
	internal func finishAndRemoveDelegates() {
		self.room?.removeDelegate(self)
		finish()
	}

	class func createRoom(name name: String, completion: (result: Bool, room: XMPPRoom) -> ()) -> MUCOperation {
		let createRoomOperation = MUCOperation()
		createRoomOperation.mainOperation = { (room: XMPPRoom) -> () in
			
			let config = DDXMLElement(name: "x", xmlns: "jabber:x:data")
			
			let formTypeConfig = DDXMLElement(name: "field")
			formTypeConfig.addAttributeWithName("var", stringValue: "FORM_TYPE")
			formTypeConfig.addChild(DDXMLElement(name: "value", stringValue: "http://jabber.org/protocol/muc#roomconfig"))
			
			let roomNameConfig = DDXMLElement(name: "field")
			roomNameConfig.addAttributeWithName("var", stringValue: "roomname")
			roomNameConfig.addChild(DDXMLElement(name: "value", stringValue: name))

			config.addChild(formTypeConfig)
			config.addChild(roomNameConfig)

			room.configureRoomUsingOptions(config)
		}
		createRoomOperation.completion = completion

		return createRoomOperation
	}
	
	class func invite(room room: XMPPRoom, userJIDs: [XMPPJID], completion: (result: Bool, room: XMPPRoom) -> ()) -> MUCOperation {
		let operation = MUCOperation(room)
		operation.mainOperation = { (room: XMPPRoom) -> () in
			for jid in userJIDs {
				room.inviteUser(jid, withMessage: room.roomSubject)
			}
		}
		operation.completion = completion
		
		return operation
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