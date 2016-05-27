//
//  XMPPRoomLightOperation.swift
//  Mangosta
//
//  Created by Andres Canal on 5/18/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class XMPPRoomLightOperation: AsyncOperation, XMPPRoomLightDelegate {

	var room: XMPPRoomLight?
	var mainOperation: ((room: XMPPRoomLight) -> ())?
	var completion: ((result: Bool, room: XMPPRoomLight?) -> ())?
	var memberListCompletion: ((result: Bool,  members: [(String, String)]?) -> ())?
	var boolCompletion: ((result: Bool) -> ())?
	let domain = "muclight.erlang-solutions.com"

	var roomJID: XMPPJID?
	
	override func execute() {
		let roomJID =  self.roomJID ?? XMPPJID.jidWithUser(XMPPStream.generateUUID(), domain: self.domain, resource: nil)

		if let xmppRoom = self.room where xmppRoom.xmppStream == nil {
			xmppRoom.activate(StreamManager.manager.stream)
		} else if self.room == nil {
			self.room = XMPPRoomLight(domain: self.domain)
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

	class func fetchMembersList(room room: XMPPRoomLight, completion: (result: Bool,  members: [(String, String)]?) -> ()) -> XMPPRoomLightOperation {
		let fetchMemberListOperation = XMPPRoomLightOperation()
		fetchMemberListOperation.room = room

		fetchMemberListOperation.mainOperation = { (room: XMPPRoomLight) in
			room.fetchMembersList()
		}
		fetchMemberListOperation.memberListCompletion = completion
		
		return fetchMemberListOperation
	}

	func xmppRoomLight(sender: XMPPRoomLight!, didFetchMembersList items: [AnyObject]!) {
//		let members = iq.elementForName("query").elementsForName("user").map { (child) -> (String, String) in
//			let ch = child as! DDXMLElement
//			return (ch.stringValue(), "")
//		}
		
		self.memberListCompletion?(result: true,  members: nil)
		self.finishAndRemoveDelegates()
	}
	
	func xmppRoomLight(sender: XMPPRoomLight!, didFailToFetchMembersList iq: XMPPIQ!) {
		self.memberListCompletion?(result: false,  members: nil)
		self.finishAndRemoveDelegates()
	}
	
	class func createRoom(name name: String, members: [XMPPJID]?, completion: (result: Bool, room: XMPPRoomLight?) -> ()) -> XMPPRoomLightOperation {
		let createRoomOperation = XMPPRoomLightOperation()
		
		createRoomOperation.mainOperation = { (room: XMPPRoomLight) in
			room.createRoomLight(name, members: members)
		}
		createRoomOperation.completion = completion
		return createRoomOperation
	}

	func xmppRoomLight(sender: XMPPRoomLight!, didCreatRoomLight iq: XMPPIQ!) {
		self.completion?(result: true, room: self.room)
		self.finishAndRemoveDelegates()
	}

	func xmppRoomLight(sender: XMPPRoomLight!, didFailToCreateRoomLight iq: XMPPIQ!) {
		self.completion?(result: false, room: nil)
		self.finishAndRemoveDelegates()
	}

	class func leaveRoom(room room: XMPPRoomLight, completion: (result: Bool) -> ()) -> XMPPRoomLightOperation {
		let leaveRoomOperation = XMPPRoomLightOperation()
		leaveRoomOperation.room = room
		
		leaveRoomOperation.mainOperation = { (room: XMPPRoomLight) in
			room.leaveRoomLight()
		}
		leaveRoomOperation.boolCompletion = completion
		return leaveRoomOperation
	}
	
	func xmppRoomLight(sender: XMPPRoomLight!, didFailToLeaveRoomLight iq: XMPPIQ!) {
		self.boolCompletion?(result: false)
		self.finishAndRemoveDelegates()
	}
	
	func xmppRoomLight(sender: XMPPRoomLight!, didLeaveRoomLight iq: XMPPIQ!) {
		self.boolCompletion?(result: true)
		self.finishAndRemoveDelegates()
	}
	
	class func invite(room room: XMPPRoomLight, userJIDs: [XMPPJID], completion: (result: Bool) -> ()) -> XMPPRoomLightOperation {
		let inviteOperation = XMPPRoomLightOperation()
		inviteOperation.room = room

		inviteOperation.mainOperation = { (room: XMPPRoomLight) in
			room.addUsers(userJIDs)
		}

		inviteOperation.boolCompletion = completion

		return inviteOperation
	}
	
	func xmppRoomLight(sender: XMPPRoomLight!, didAddUsers iqResult: XMPPIQ!) {
		self.boolCompletion?(result: true)
		self.finishAndRemoveDelegates()
	}
	
	func xmppRoomLight(sender: XMPPRoomLight!, didFailToAddUsers iq: XMPPIQ!) {
		self.boolCompletion?(result: false)
		self.finishAndRemoveDelegates()
	}
}
