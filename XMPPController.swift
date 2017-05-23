//
//  XMPPController.swift
//  Mangosta
//
//  Created by Andres Canal on 6/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class XMPPController: NSObject {

    static let sharedInstance = XMPPController()
    
	var xmppStream: XMPPStream
	var xmppReconnect: XMPPReconnect
	var xmppRoster: XMPPRoster
	var xmppRosterStorage: XMPPRosterCoreDataStorage
	var xmppRosterCompletion: RosterCompletion?
    var xmppServiceDiscovery: XMPPServiceDiscovery
	var xmppCapabilities: XMPPCapabilities
	var xmppCapabilitiesStorage: XMPPCapabilitiesCoreDataStorage
    var xmppCapabilitiesMyFeatures: Set<String> {
        didSet {
            xmppCapabilities.recollectMyCapabilities()
        }
    }

    var xmppMicrobloggingPubSub: XMPPPubSub
    var xmppPushNotificationsPubSub: XMPPPubSub
    
	var xmppMUCStorage: XMPPMUCCoreDataStorage
	var xmppMUCStorer: XMPPMUCStorer
	var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	var xmppMessageArchiveManagement: XMPPMessageArchiveManagement
	var xmppRoomLightCoreDataStorage: XMPPRoomLightCoreDataStorage
	var xmppMessageDeliveryReceipts: XMPPMessageDeliveryReceipts
	var xmppMessageCarbons: XMPPMessageCarbons

	var xmppStreamManagement: XMPPStreamManagement
	var xmppStreamManagementStorage: XMPPStreamManagementDiscStorage

	var roomsLight = [XMPPRoomLight]()
    var xmppOneToOneChat: XMPPOneToOneChat
    
    // TODO: [pwe] consider dropping XEP-0352 on iOS; the XMPP socket is torn down when going into background anyway
    let xmppClientState: XMPPClientState
    let xmppPushNotifications: XMPPPushNotifications

    var hostPort: UInt16 = 5222
    var password: String = ""
    
    var isXmppConnected = false
		
    weak var pushNotificationsDelegate: XMPPControllerPushNotificationsDelegate?
    weak var microbloggingDelegate: XMPPControllerMicrobloggingDelegate? {
        didSet {
            if microbloggingDelegate != nil {
                xmppCapabilitiesMyFeatures.insert(XMPPCapabilitiesMicroblogImplicitSubscription)
            } else {
                xmppCapabilitiesMyFeatures.remove(XMPPCapabilitiesMicroblogImplicitSubscription)
            }
        }
    }
    
    override init() {
        self.xmppStream = XMPPStream()
		self.xmppReconnect = XMPPReconnect()

		// Roster
		self.xmppRosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
		self.xmppRoster = XMPPRoster(rosterStorage: self.xmppRosterStorage)
		self.xmppRoster.autoFetchRoster = true
        self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = true
		
        // Service Discovery
        self.xmppServiceDiscovery = XMPPServiceDiscovery()
        
		// Capabilities
		self.xmppCapabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.xmppCapabilities = XMPPCapabilities(capabilitiesStorage: self.xmppCapabilitiesStorage)
		self.xmppCapabilities.autoFetchHashedCapabilities = true
		self.xmppCapabilities.autoFetchNonHashedCapabilities = false
        self.xmppCapabilities.myCapabilitiesNode = "https://github.com/esl/mangosta-ios"
        self.xmppCapabilitiesMyFeatures = []
		
        // PubSub
        self.xmppMicrobloggingPubSub = XMPPPubSub(serviceJID: nil, dispatchQueue: DispatchQueue.main)
        self.xmppPushNotificationsPubSub = MIMPushNotificationsPubSub(serviceJID: XMPPJID(string: "pubsub.erlang-solutions.com"))
        
		// Delivery Receips
		self.xmppMessageDeliveryReceipts = XMPPMessageDeliveryReceipts()
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryReceipts = true
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryRequests = true

		// Message Carbons
		self.xmppMessageCarbons = XMPPMessageCarbons()
		self.xmppMessageCarbons.autoEnableMessageCarbons = true
		self.xmppMessageCarbons.enable()

		// Stream Managment
		self.xmppStreamManagementStorage = XMPPStreamManagementDiscStorage()
		self.xmppStreamManagement = XMPPStreamManagement(storage: self.xmppStreamManagementStorage)
		self.xmppStreamManagement.autoResume = true
        
        // TODO: [pwe] microblog should not depend on initial presence-based last item delivery each time the app is started
        self.xmppStreamManagementStorage.removeAll(for: self.xmppStream)

        self.xmppMessageArchivingStorage = XMPPMessageArchivingCoreDataStorage()
        self.xmppRoomLightCoreDataStorage = XMPPRoomLightCoreDataStorage()
        
        self.xmppOneToOneChat = XMPPOneToOneChat(messageArchivingStorage: self.xmppMessageArchivingStorage)
        
		self.xmppMessageArchiveManagement = XMPPMessageArchiveManagement()
        self.xmppMessageArchiveManagement.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)

		self.xmppMUCStorage = XMPPMUCCoreDataStorage()
		self.xmppMUCStorer = XMPPMUCStorer(roomStorage: self.xmppMUCStorage)
        
        self.xmppClientState = XMPPClientState()
        
        let pushNotificationsEnvironment: XMPPPushNotificationsEnvironment
        #if APNS_SANDBOX
            pushNotificationsEnvironment = .sandbox
        #elseif APNS_PRODUCTION
            pushNotificationsEnvironment = .production
        #endif
        self.xmppPushNotifications = XMPPPushNotifications(
            pubSubServiceJid: self.xmppPushNotificationsPubSub.serviceJID,
            nodeName: (UIDevice.current.identifierForVendor ?? UUID()).uuidString,    // in rare cases where identifierForVendor returns nil, use a temporary UUID for simplicity
            environment: pushNotificationsEnvironment
        )

		// Activate xmpp modules
		self.xmppReconnect.activate(self.xmppStream)
		self.xmppRoster.activate(self.xmppStream)
        self.xmppServiceDiscovery.activate(self.xmppStream)
		self.xmppCapabilities.activate(self.xmppStream)
        self.xmppMicrobloggingPubSub.activate(self.xmppStream)
        self.xmppPushNotificationsPubSub.activate(self.xmppStream)
		self.xmppMessageDeliveryReceipts.activate(self.xmppStream)
		self.xmppMessageCarbons.activate(self.xmppStream)
		self.xmppStreamManagement.activate(self.xmppStream)
		self.xmppMUCStorer.activate(self.xmppStream)
		self.xmppMessageArchiveManagement.activate(self.xmppStream)
        self.xmppOneToOneChat.activate(self.xmppStream)
        self.xmppClientState.activate(self.xmppStream)
        self.xmppPushNotifications.activate(self.xmppStream)
		

		// Stream Settings
		self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed

		super.init()
		
        // Add delegates
		self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppServiceDiscovery.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppCapabilities.addDelegate(self, delegateQueue: DispatchQueue.main)
		self.xmppStreamManagement.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppReconnect.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppMicrobloggingPubSub.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppPushNotificationsPubSub.addDelegate(self, delegateQueue: DispatchQueue.main)
	}

    func setStreamCredentials(_ hostName: String?, userJID: XMPPJID, hostPort: UInt16 = 5222, password: String) {
        if let host = hostName, hostName?.characters.count > 0 {
            self.xmppStream.hostName = host
        }
        self.xmppStream.myJID = userJID
        self.xmppStream.hostPort = hostPort
        self.password = password
    }
    
	func connect() -> Bool {
        
		if !self.xmppStream.isDisconnected() {
			return true
		}
		
        guard let authModel =  AuthenticationModel.load() else {
            return false
        }

        self.setStreamCredentials(authModel.serverName, userJID: authModel.jid, password: authModel.password)
        
        do {
           try self.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
        }
        catch {
            return false
        }
        return true
	}

	func disconnect() {
    
		self.goOffLine()
		self.xmppStream.disconnectAfterSending()
	}

    func enablePushNotifications(withDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02x", $0) } .joined()
        // TODO: [pwe] MIM currently requires explicit `topic` value to be provided when pushing using universal APNS certificates
        xmppPushNotifications.enable(withDeviceTokenString: deviceTokenString, customOptions: ["topic": Bundle.main.bundleIdentifier!])
    }
    
    func publishMicroblogEntry(withTitle title: String) -> String {
        let now = Date()
        return xmppMicrobloggingPubSub.publish(
            toNode: XMPPPubSubDefaultMicroblogNode,
            entry: .microblogEntry(withTitle: title, authorName: xmppStream.myJID.user, authorJID: xmppStream.myJID, publishedDate: now, updatedDate: now)
        )
    }

    deinit {
        self.tearDownStream()
    }
    
	func tearDownStream() {
        self.xmppStream.removeDelegate(self)
        self.xmppRoster.removeDelegate(self)
        self.xmppMicrobloggingPubSub.removeDelegate(self)
        self.xmppPushNotificationsPubSub.removeDelegate(self)
        self.xmppServiceDiscovery.removeDelegate(self)
        self.xmppCapabilities.removeDelegate(self)
        
		self.roomsLight.forEach { (roomLight) in
			roomLight.deactivate()
		}
        
		self.xmppReconnect.deactivate()
		self.xmppRoster.deactivate()
        self.xmppServiceDiscovery.deactivate()
		self.xmppCapabilities.deactivate()
        
        self.xmppMicrobloggingPubSub.deactivate()
        self.xmppPushNotificationsPubSub.deactivate()
		self.xmppMessageDeliveryReceipts.deactivate()
		self.xmppMessageCarbons.deactivate()
		self.xmppStreamManagement.deactivate()
		self.xmppMUCStorer.deactivate()
		self.xmppMessageArchiveManagement.deactivate()
        self.xmppOneToOneChat.deactivate()
        self.xmppClientState.deactivate()
        self.xmppPushNotifications.deactivate()
        
        self.disconnect()
        
        self.xmppStream.myJID = nil
        self.xmppStream.hostName = nil
        self.password = ""
	}
}

extension XMPPController: XMPPStreamDelegate {

	func xmppStreamDidConnect(_ stream: XMPPStream!) {
        self.isXmppConnected = true
		
        let user = stream.myJID.bare() as String
		print("Stream: Connected as user: \(user).")
		try! stream.authenticate(withPassword: self.password)
	}

	func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
		self.xmppStreamManagement.enable(withResumption: true, maxTimeout: 1000)
		print("Stream: Authenticated")
		self.goOnline()
        
        self.xmppServiceDiscovery.discoverInformationAbout(xmppStream.myJID.domain()) // TODO: xmppStream.myJID.bareJID()
	}
	
	func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
		print("Stream: Fail to Authenticate")
	}
	
    func xmppStreamWasTold(toDisconnect sender: XMPPStream!) {
        print("Stream was told to disconnect.")
    }
    
	func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
		print("Stream: Disconnected")
        if !self.isXmppConnected {
            print("Unable to connect to server. Check xmppStream.hostName")
          //  self.xmppReconnect.manualStart()
        }
        self.isXmppConnected = false
	}
    
    func xmppStreamDidChangeMyJID(_ xmppStream: XMPPStream!) {
        print("Stream: new JID: \((xmppStream.myJID.bare() as String))")
    }
	
	func goOnline() {
		let presence = XMPPPresence()
		self.xmppStream.send(presence)
        
        xmppClientState.isActive = true
	}
	
	func goOffLine() {
		let presence = XMPPPresence(type: "unavailable")
		self.xmppStream.send(presence)
        
        xmppClientState.isActive = false
        
	}
}

extension XMPPController: XMPPStreamManagementDelegate {

	func xmppStreamManagement(_ sender: XMPPStreamManagement!, wasEnabled enabled: DDXMLElement!) {
		print("Stream Management: enabled")
	}

	func xmppStreamManagement(_ sender: XMPPStreamManagement!, wasNotEnabled failed: DDXMLElement!) {
		print("Stream Management: not enabled")
	}
	
}

extension XMPPController: XMPPRosterDelegate {
	func xmppStream(_ sender: XMPPStream!, didReceive presence: XMPPPresence!) {
        print("Received presence type \(presence.type()) from \(presence.fromStr())")
    }
	
	func xmppRoster(_ sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
		print("Roster: Received presence request from user: \((presence.from().bare() as String))")
	}
}

extension XMPPController: XMPPPubSubDelegate {
    func xmppPubSub(_ sender: XMPPPubSub!, didCreateNode node: String!, withResult iq: XMPPIQ!) {
        switch sender {
        case xmppPushNotificationsPubSub:
            pushNotificationsDelegate?.xmppControllerDidPrepareForPushNotificationsSupport(self)
        default:
            break
        }
        print("PubSub: Did create node")
    }
    func xmppPubSub(_ sender: XMPPPubSub!, didNotCreateNode node: String!, withError iq: XMPPIQ!) {
        switch sender {
        case xmppPushNotificationsPubSub where iq.childErrorElement().attributeIntegerValue(forName: "code") == 409:
            // assuming 409 means a node had been created earlier
            pushNotificationsDelegate?.xmppControllerDidPrepareForPushNotificationsSupport(self)
        default:
            break
        }
        print("PubSub: Did not create node: \(iq.stringValue)")
    }
    
    func xmppPubSub(_ sender: XMPPPubSub!, didPublishToNode node: String!, withResult iq: XMPPIQ!) {
        switch sender {
        case xmppMicrobloggingPubSub:
            microbloggingDelegate?.xmppController(self, didPublishMicroblogEntryWithRequestID: iq.elementID())
        default:
            break
        }
    }
    
    func xmppPubSub(_ sender: XMPPPubSub!, didNotPublishToNode node: String!, withError iq: XMPPIQ!) {
        switch sender {
        case xmppMicrobloggingPubSub:
            microbloggingDelegate?.xmppController(self, didFailToPublishMicroblogEntryWithRequestID: iq.elementID())
        default:
            break
        }
    }
    
    func xmppPubSub(_ sender: XMPPPubSub!, shouldReceiveForeignMessage message: XMPPMessage!) -> Bool {
        switch sender {
        case xmppMicrobloggingPubSub where message.isPubSubItemsEventMessage(fromNode: XMPPPubSubDefaultMicroblogNode):
            return true
        default:
            return false
        }
    }
    
    func xmppPubSub(_ sender: XMPPPubSub!, didReceive message: XMPPMessage!) {
        switch sender {
        case xmppMicrobloggingPubSub:
            handleMicroblogMessage(message)
        default:
            break
        }
    }
    
    func handleMicroblogMessage(_ message: XMPPMessage) {
        let microblogEntries = message.pubSubItemsEventPayloads().filter { $0.isMicroblogEntry() }
        guard !microblogEntries.isEmpty else {
            return
        }
        
        microbloggingDelegate?.xmppController(self, didReceiveMicroblogEntries: microblogEntries, from: message.from())
    }
}

extension XMPPController: XMPPServiceDiscoveryDelegate {
    
    func xmppServiceDiscovery(_ sender: XMPPServiceDiscovery!, didDiscoverInformation items: [Any]!) {
        for item in items {
            switch item {
            case let xmppElement as DDXMLElement where xmppElement.isPushNotificationFeatureElement():
                // TODO: [pwe] ideally, we should wait for the device token before proceeding with pubsub node creation
                xmppPushNotificationsPubSub.createNode(xmppPushNotifications.nodeName)
                
            default:
                continue
            }
        }
    }
}

extension XMPPController: XMPPCapabilitiesDelegate {
    
    func myFeatures(for sender: XMPPCapabilities!) -> [Any]! {
        return Array(xmppCapabilitiesMyFeatures)
    }
}

extension XMPPController {
    func managedObjectContext_roster() -> NSManagedObjectContext {
        return self.xmppRosterStorage.mainThreadManagedObjectContext
    }
    
    func managedObjectContext_Capabilities() -> NSManagedObjectContext {
        return self.xmppCapabilitiesStorage.mainThreadManagedObjectContext
    }
    
}

protocol XMPPControllerPushNotificationsDelegate: class {
    
    func xmppControllerDidPrepareForPushNotificationsSupport(_ controller: XMPPController)
}

protocol XMPPControllerMicrobloggingDelegate: class {
    
    func xmppController(_ controller: XMPPController, didPublishMicroblogEntryWithRequestID requestID: String)
    
    // TODO: [pwe] deliver error information
    func xmppController(_ controller: XMPPController, didFailToPublishMicroblogEntryWithRequestID requestID: String)
    
    func xmppController(_ controller: XMPPController, didReceiveMicroblogEntries microblogEntries: [DDXMLElement], from publisherJID: XMPPJID)
}
