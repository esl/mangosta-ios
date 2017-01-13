//
//  XMPPController.swift
//  Mangosta
//
//  Created by Andres Canal on 6/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class XMPPController: NSObject {

	var xmppStream: XMPPStream
	var xmppReconnect: XMPPReconnect
	var xmppRoster: XMPPRoster
	var xmppRosterStorage: XMPPRosterCoreDataStorage
	var xmppRosterCompletion: RosterCompletion?
	var xmppCapabilities: XMPPCapabilities
	var xmppCapabilitiesStorage: XMPPCapabilitiesCoreDataStorage

	var xmppMUCStorage: XMPPMUCCoreDataStorage
	var xmppMUCStorer: XMPPMUCStorer
	var xmppMessageArchiving: XMPPMessageArchivingWithMAM
	var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	var xmppMessageArchiveManagement: XMPPMessageArchiveManagement
	var xmppRoomLightCoreDataStorage: XMPPRoomLightCoreDataStorage
	var xmppMessageDeliveryReceipts: XMPPMessageDeliveryReceipts
	var xmppMessageCarbons: XMPPMessageCarbons

	var xmppStreamManagement: XMPPStreamManagement
	var xmppStreamManagementStorage: XMPPStreamManagementDiscStorage

	var roomsLight = [XMPPRoomLight]()

	let hostName: String
	let userJID: XMPPJID
	let hostPort: UInt16
	let password: String
	
	var activated = true

	init(hostName: String, userJID: XMPPJID, hostPort: UInt16 = 5222, password: String) {
		self.hostName = hostName
		self.userJID = userJID
		self.hostPort = hostPort
		self.password = password

		self.xmppStream = XMPPStream()
		self.xmppReconnect = XMPPReconnect()

		// Roster
		self.xmppRosterStorage = XMPPRosterCoreDataStorage()
		self.xmppRoster = XMPPRoster(rosterStorage: self.xmppRosterStorage)
		self.xmppRoster.autoFetchRoster = true;
		
		// Capabilities
		self.xmppCapabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.xmppCapabilities = XMPPCapabilities(capabilitiesStorage: self.xmppCapabilitiesStorage)
		self.xmppCapabilities.autoFetchHashedCapabilities = true
		self.xmppCapabilities.autoFetchNonHashedCapabilities = false
		
		// Delivery Receips
		self.xmppMessageDeliveryReceipts = XMPPMessageDeliveryReceipts()
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryReceipts = true
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryRequests = true

		// Message Carbons
		self.xmppMessageCarbons = XMPPMessageCarbons()
		self.xmppMessageCarbons.autoEnableMessageCarbons = true
		self.xmppMessageCarbons.enableMessageCarbons()

		// Stream Managment
		self.xmppStreamManagementStorage = XMPPStreamManagementDiscStorage()
		self.xmppStreamManagement = XMPPStreamManagement(storage: self.xmppStreamManagementStorage)
		self.xmppStreamManagement.autoResume = true

		self.xmppMessageArchiveManagement = XMPPMessageArchiveManagement()

		self.xmppMUCStorage = XMPPMUCCoreDataStorage(databaseFilename: "\(self.userJID).muc.sqlite", storeOptions: nil)
		self.xmppMUCStorer = XMPPMUCStorer(roomStorage: self.xmppMUCStorage)
		
		self.xmppMessageArchivingStorage = XMPPMessageAndMAMArchivingCoreDataStorage(databaseFilename: "\(self.userJID).messages.sqlite", storeOptions: nil)
		self.xmppMessageArchiving = XMPPMessageArchivingWithMAM(messageArchivingStorage: self.xmppMessageArchivingStorage)
		self.xmppRoomLightCoreDataStorage = XMPPRoomLightCoreDataStorage(databaseFilename: "\(self.userJID).muc-light.sqlite", storeOptions: nil)

		// Activate xmpp modules
		self.xmppReconnect.activate(self.xmppStream)
		self.xmppRoster.activate(self.xmppStream)
		self.xmppCapabilities.activate(self.xmppStream)
		self.xmppMessageDeliveryReceipts.activate(self.xmppStream)
		self.xmppMessageCarbons.activate(self.xmppStream)
		self.xmppStreamManagement.activate(self.xmppStream)
		self.xmppMUCStorer.activate(self.xmppStream)
		self.xmppMessageArchiving.activate(self.xmppStream)
		self.xmppMessageArchiveManagement.activate(self.xmppStream)
		

		// Stream Settings
		self.xmppStream.hostName = hostName
		self.xmppStream.hostPort = hostPort
		self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.Allowed
		self.xmppStream.myJID = userJID

		super.init()
		
		self.xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.xmppStreamManagement.addDelegate(self, delegateQueue: dispatch_get_main_queue())
	}

	func connect() {
		if !self.xmppStream.isDisconnected() {
			return
		}

		try! self.xmppStream.connectWithTimeout(XMPPStreamTimeoutNone)
	}

	func disconnect() {
		self.xmppStream.disconnect()
	}
	
	func  setXEP0352(active: Bool) {
		if activated {
			self.xmppStream.sendElement(XMPPElement.indicateInactiveElement())
			self.activated = false

		} else {
			self.xmppStream.sendElement(XMPPElement.indicateActiveElement())
			self.activated = true
		}
		print("XEP-0352 set to " + (active ? "active":"inactive") + ".")
	}

	deinit {
		self.roomsLight.forEach { (roomLight) in
			roomLight.deactivate()
		}
		self.roomsLight = [XMPPRoomLight]()
		
		self.xmppStream.removeDelegate(self)
		self.xmppReconnect.deactivate()
		self.xmppRoster.deactivate()
		self.xmppCapabilities.deactivate()
		self.xmppMessageDeliveryReceipts.deactivate()
		self.xmppMessageCarbons.deactivate()
		self.xmppStreamManagement.deactivate()
		self.xmppMUCStorer.deactivate()
		self.xmppMessageArchiving.deactivate()
		self.xmppMessageArchiveManagement.deactivate()

		self.xmppStream.disconnect()
	}
}

extension XMPPController: XMPPStreamDelegate {

	func xmppStreamDidConnect(stream: XMPPStream!) {
		print("Stream: Connected")
		try! stream.authenticateWithPassword(self.password)
	}

	func xmppStreamDidAuthenticate(sender: XMPPStream!) {
		self.xmppStreamManagement.enableStreamManagementWithResumption(true, maxTimeout: 1000)
		print("Stream: Authenticated")
		self.goOnline()
	}
	
	func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
		print("Stream: Fail to Authenticate")
	}
	
	func goOnline() {
		let presence = XMPPPresence()
		self.xmppStream.sendElement(presence)
	}
	
	func goOffLine() {
		let presence = XMPPPresence(type: "unavailable")
		self.xmppStream.sendElement(presence)
	}
}

extension XMPPController: XMPPStreamManagementDelegate {

	func xmppStreamManagement(sender: XMPPStreamManagement!, wasEnabled enabled: DDXMLElement!) {
		print("Stream Management: enabled")
	}

	func xmppStreamManagement(sender: XMPPStreamManagement!, wasNotEnabled failed: DDXMLElement!) {
		print("Stream Management: not enabled")
	}
	
}