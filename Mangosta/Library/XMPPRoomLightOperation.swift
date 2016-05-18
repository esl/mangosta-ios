//
//  XMPPRoomLightOperation.swift
//  Mangosta
//
//  Created by Andres Canal on 5/18/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class XMPPRoomLightOperation: AsyncOperation, XMPPMUCLightDelegate {

	var room: XMPPMUCLight?
	var mainOperation: ((room: XMPPMUCLight) -> ())?
	var completion: ((result: Bool, room: XMPPMUCLight?) -> ())?
	var memberListCompletion: ((result: Bool,  members: [(String, String)]?) -> ())?
	let domain = "muclight.erlang-solutions.com"

	var roomJID: XMPPJID?
	
	override func execute() {
		let roomJID =  self.roomJID ?? XMPPJID.jidWithUser(XMPPStream.generateUUID(), domain: self.domain, resource: nil)

		if let xmppRoom = self.room where xmppRoom.xmppStream == nil {
			xmppRoom.activate(StreamManager.manager.stream)
		} else if self.room == nil {
			self.room = XMPPMUCLight(roomStorage: XMPPRoomMemoryStorage(), jid: roomJID!, dispatchQueue: dispatch_get_main_queue())
			self.room?.activate(StreamManager.manager.stream)
		}
		
		self.room?.xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.room?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		self.mainOperation?(room: self.room!)
	}
	
	internal func finishAndRemoveDelegates() {
		self.room?.removeDelegate(self)
		self.room?.deactivate()
		finish()
	}

	class func fetchMembersList(room room: XMPPMUCLight, completion: (result: Bool,  members: [(String, String)]?) -> ()) -> XMPPRoomLightOperation {
		let fetchMemberListOperation = XMPPRoomLightOperation()
		fetchMemberListOperation.room = room

		fetchMemberListOperation.mainOperation = { (room: XMPPMUCLight) in
			room.fetchAllMembersList()
		}
		fetchMemberListOperation.memberListCompletion = completion
		
		return fetchMemberListOperation
	}

	func xmppRoom(sender: XMPPMUCLight!, didFetchedAllMembers iq: XMPPIQ!) {

		let members = iq.elementForName("query").elementsForName("user").map { (child) -> (String, String) in
			let ch = child as! DDXMLElement
			return (ch.stringValue(), "")
		}

		self.memberListCompletion?(result: true,  members: members)
		self.finishAndRemoveDelegates()
	}
	
	func xmppRoom(sender: XMPPMUCLight!, didFailToFetchAllMembers iq: XMPPIQ!) {
		self.memberListCompletion?(result: false,  members: nil)
		self.finishAndRemoveDelegates()
	}

	class func createRoom(name name: String, members: [XMPPJID]?, completion: (result: Bool, room: XMPPMUCLight?) -> ()) -> XMPPRoomLightOperation {
		let createRoomOperation = XMPPRoomLightOperation()
		
		createRoomOperation.mainOperation = { (room: XMPPMUCLight) in
				room.createMUCLightRoom(name, members: members)
		}
		createRoomOperation.completion = completion
		return createRoomOperation
	}

	func xmppRoom(sender: XMPPMUCLight!, didCreateMUCLightRoom iq: XMPPIQ!) {
		self.completion?(result: true, room: self.room)
		self.finishAndRemoveDelegates()
	}

	func xmppRoom(sender: XMPPMUCLight!, didFailToCreateMUCLightRoom iq: XMPPIQ!) {
		self.completion?(result: false, room: nil)
		self.finishAndRemoveDelegates()
	}
}
