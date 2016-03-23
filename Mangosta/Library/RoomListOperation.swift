//
//  RoomListOperation.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/18/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

class RoomListOperation: AsyncOperation, XMPPMUCDelegate {
	var completion: RoomListCompletion?
	var muc: XMPPMUC
	
	private override init() {
		self.muc = XMPPMUC(dispatchQueue: dispatch_get_main_queue())
		
		super.init()
		
		self.muc.addDelegate(self, delegateQueue: dispatch_get_main_queue())
	}
	
	class func retrieveRooms(completion: RoomListCompletion) -> RoomListOperation {
		let chatRoomListOperation = RoomListOperation()
		chatRoomListOperation.completion = completion
		return chatRoomListOperation
	}
	
	override func execute() {
		self.muc.activate(StreamManager.manager.stream)
		self.muc.discoverServices()
		self.muc.discoverRoomsForServiceNamed("muc.mongooseim.local")
	}
	
	internal func finishAndRemoveDelegates(){
		self.muc.deactivate()
		self.muc.removeDelegate(self)
		finish()
	}
	
	// MARK: - XMPPMUCDelegate
	
	func xmppMUC(sender: XMPPMUC!, didDiscoverRooms rooms: [AnyObject]!, forServiceNamed serviceName: String!) {
		guard let xmlRooms = rooms as! [DDXMLElement]! else {
			self.finishedRetrievingRooms(nil)
			return
		}
		let parsedRooms = RoomListOperation.parseRoomsFromXMLRooms(xmlRooms)
		self.finishedRetrievingRooms(parsedRooms)
	}
	
	func xmppMUC(sender: XMPPMUC!, failedToDiscoverRoomsForServiceNamed serviceName: String!, withError error: NSError!) {
		self.finishedRetrievingRooms(nil)
	}
	
	func xmppMUC(sender: XMPPMUC!, roomJID: XMPPJID!, didReceiveInvitation message: XMPPMessage!) {
		print(message)
	}
	
	// MARK: - Private
	
	private func finishedRetrievingRooms(rooms: [XMPPRoom]?) {
		self.completionBlock = {
			dispatch_async(dispatch_get_main_queue()) {
				self.completion?(rooms)
			}
		}
		self.finishAndRemoveDelegates()
	}
	
	class func parseRoomsFromXMLRooms(xmlRooms: [DDXMLElement]) -> [XMPPRoom]{
		var parsedRooms = [XMPPRoom]()
		for rawElement in xmlRooms {
			let rawJid = rawElement.attributeStringValueForName("jid")
			let rawName = rawElement.attributeStringValueForName("name")
			let jid = XMPPJID.jidWithString(rawJid)
			if let room = StreamManager.manager.roomForJid(jid) {
				//room.attachAndActivateXmppMucLightRoom()
				parsedRooms.append(room)
			} else {
				let r = XMPPRoom(roomStorage: StreamManager.manager.roomStorage, jid: jid)
				
				parsedRooms.append(r)
			}
		}
		return parsedRooms
	}
}