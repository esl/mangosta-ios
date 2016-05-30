//
//  XMPPMUCLightOperation.swift
//  Mangosta
//
//  Created by Andres on 5/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class XMPPMUCLightOperation: AsyncOperation, XMPPMUCLightDelegate {

	var completion: (([XMPPRoomLight]?)->())?
	var mucLight: XMPPMUCLight!
	static let mucDomain = "muclight.erlang-solutions.com"
	var domain = ""
	
	class func retrieveRooms(completion: ([XMPPRoomLight]?)->() = {_ in }) -> XMPPMUCLightOperation {
		let chatRoomListOperation = XMPPMUCLightOperation()
		chatRoomListOperation.domain = XMPPMUCLightOperation.mucDomain
		chatRoomListOperation.completion = completion
		return chatRoomListOperation
	}
	
	override func execute() {
		self.mucLight = XMPPMUCLight(dispatchQueue: dispatch_get_main_queue())
		self.mucLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.mucLight.activate(StreamManager.manager.stream)
		self.mucLight.discoverRoomsForServiceNamed(self.domain)
	}
	
	internal func finishAndRemoveDelegates(){
		self.mucLight.deactivate()
		self.mucLight.removeDelegate(self)
		finish()
	}
	
	class func parseRoomsFromXMLRooms(xmlRooms: [DDXMLElement]) -> [XMPPRoomLight]{
		var parsedRooms = [XMPPRoomLight]()
		for rawElement in xmlRooms {
			let rawJid = rawElement.attributeStringValueForName("jid")
			let rawName = rawElement.attributeStringValueForName("name")
			let jid = XMPPJID.jidWithString(rawJid)
			
			var r: XMPPRoomLight?
			if jid.domain == XMPPMUCLightOperation.mucDomain {
				r = XMPPRoomLight(JID: jid, roomname: rawName)
				parsedRooms.append(r!)
			}
		}
		return parsedRooms
	}
	
	// MARK: - XMPPMUCDelegate
	
	func xmppMUCLight(sender: XMPPMUCLight!, didDiscoverRooms rooms: [AnyObject]!, forServiceNamed serviceName: String!) {
		guard let xmlRooms = rooms as! [DDXMLElement]! else {
			self.finishedRetrievingRooms(nil)
			return
		}
		let parsedRooms = XMPPMUCLightOperation.parseRoomsFromXMLRooms(xmlRooms)
		self.finishedRetrievingRooms(parsedRooms)
	}
	
	func xmppMUCLight(sender: XMPPMUCLight!, failedToDiscoverRoomsForServiceNamed serviceName: String!, withError error: NSError!) {
		self.finishedRetrievingRooms(nil)
	}
	
	func xmppMUCLight(sender: XMPPMUCLight!, roomJID: XMPPJID!, didReceiveInvitation message: XMPPMessage!) {

	}
	
	// MARK: - Private
	
	private func finishedRetrievingRooms(rooms: [XMPPRoomLight]?) {
		self.completionBlock = {
			dispatch_async(dispatch_get_main_queue()) {
				self.completion?(rooms)
			}
		}
		self.finishAndRemoveDelegates()
	}
	
}
