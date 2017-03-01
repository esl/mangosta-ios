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

    static let sharedInstance = XMPPController()
    
	var xmppStream: XMPPStream
	var xmppReconnect: XMPPReconnect
	var xmppRoster: XMPPRoster
	var xmppRosterStorage: XMPPRosterCoreDataStorage
	var xmppRosterCompletion: RosterCompletion?
	var xmppCapabilities: XMPPCapabilities
	var xmppCapabilitiesStorage: XMPPCapabilitiesCoreDataStorage

    var xmppPubSub: XMPPPubSub
    
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
    
    let myMicroblogNode = "urn:xmpp:microblog:0"

    var hostPort: UInt16 = 5222
    var password: String = ""
    
	var activated = true
    
    convenience init(hostName: String, userJID: XMPPJID, hostPort: UInt16 = 5222, password: String) {
        self.init()
		self.xmppStream.hostName = hostName
		self.xmppStream.myJID = userJID
		self.xmppStream.hostPort = hostPort
        self.password = password
    }
		
        override init() {
        self.xmppStream = XMPPStream()
		self.xmppReconnect = XMPPReconnect()

		// Roster
		self.xmppRosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
		self.xmppRoster = XMPPRoster(rosterStorage: self.xmppRosterStorage)
		self.xmppRoster.autoFetchRoster = true;
		
		// Capabilities
		self.xmppCapabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.xmppCapabilities = XMPPCapabilities(capabilitiesStorage: self.xmppCapabilitiesStorage)
		self.xmppCapabilities.autoFetchHashedCapabilities = true
		self.xmppCapabilities.autoFetchNonHashedCapabilities = false
        self.xmppCapabilities.myCapabilitiesNode = myMicroblogNode + "+notify"
		
        // PubSub
        self.xmppPubSub = XMPPPubSub(serviceJID: nil, dispatchQueue: dispatch_get_main_queue()) // FIME: use pubsub.erlang-solutions.com ??
        
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

		self.xmppMUCStorage = XMPPMUCCoreDataStorage()
		self.xmppMUCStorer = XMPPMUCStorer(roomStorage: self.xmppMUCStorage)
		
		self.xmppMessageArchivingStorage = XMPPMessageAndMAMArchivingCoreDataStorage.sharedInstance()
		self.xmppMessageArchiving = XMPPMessageArchivingWithMAM(messageArchivingStorage: self.xmppMessageArchivingStorage)
		self.xmppRoomLightCoreDataStorage = XMPPRoomLightCoreDataStorage()

		// Activate xmpp modules
		self.xmppReconnect.activate(self.xmppStream)
		self.xmppRoster.activate(self.xmppStream)
		self.xmppCapabilities.activate(self.xmppStream)
        self.xmppPubSub.activate(self.xmppStream)
		self.xmppMessageDeliveryReceipts.activate(self.xmppStream)
		self.xmppMessageCarbons.activate(self.xmppStream)
		self.xmppStreamManagement.activate(self.xmppStream)
		self.xmppMUCStorer.activate(self.xmppStream)
		self.xmppMessageArchiving.activate(self.xmppStream)
		self.xmppMessageArchiveManagement.activate(self.xmppStream)
		

		// Stream Settings
		self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.Allowed

		super.init()
		
		self.xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.xmppStreamManagement.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        self.xmppPubSub.addDelegate(self, delegateQueue: dispatch_get_main_queue())
	}

	func connect() -> Bool {
        
		if !self.xmppStream.isDisconnected() {
			return true
		}
		
        do {
           try self.xmppStream.connectWithTimeout(XMPPStreamTimeoutNone)
        }
        catch {
            return false
        }
        return true
	}

	func disconnect() {
      //  self.xmppStream.myJID = nil
      //  self.xmppStream.hostName = nil
        
		self.goOffLine()
		self.xmppStream.disconnect()
	}
	
	func setXEP0352(active: Bool) {
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
        self.xmppPubSub.deactivate()
		self.xmppMessageDeliveryReceipts.deactivate()
		self.xmppMessageCarbons.deactivate()
		self.xmppStreamManagement.deactivate()
		self.xmppMUCStorer.deactivate()
		self.xmppMessageArchiving.deactivate()
		self.xmppMessageArchiveManagement.deactivate()
		
		self.disconnect()
	}
}

extension XMPPController: XMPPStreamDelegate {

	func xmppStreamDidConnect(stream: XMPPStream!) {
		let user = stream.myJID.bare()
		print("Stream: Connected as user: \(user).")
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
	
	func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
		print("Stream: Disconnected")
	}
	
	func goOnline() {
		let presence = XMPPPresence()
		self.xmppStream.sendElement(presence)
        
        self.setXEP0352(true)
        
        self.createMyPubSubNode()
	}
	
	func goOffLine() {
		let presence = XMPPPresence(type: "unavailable")
		self.xmppStream.sendElement(presence)
        
        self.setXEP0352(false)
        
	}
    
    func createMyPubSubNode() {
        xmppPubSub.createNode(myMicroblogNode)
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

extension XMPPController: XMPPRosterDelegate {
	func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        print("Received presence type \(presence.type()) from \(presence.fromStr())")
    }
	
	func xmppRoster(sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
		print("Roster: Received presence request from user: \(presence.from().bare())")
	}
}

extension XMPPController: XMPPPubSubDelegate {
    func xmppPubSub(sender: XMPPPubSub!, didCreateNode node: String!, withResult iq: XMPPIQ!) {
        print("PubSub: Did create node")
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotCreateNode node: String!, withError iq: XMPPIQ!) {
        print("PubSub: Did not create node")
    }
}
