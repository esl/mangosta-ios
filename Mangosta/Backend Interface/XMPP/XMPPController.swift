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
    var xmppStreamManagement: XMPPStreamManagement
    var xmppRetransmission: XMPPRetransmission
	
    var xmppRoster: XMPPRoster
	var xmppRosterStorage: XMPPRosterCoreDataStorage
    
    var xmppServiceDiscovery: XMPPServiceDiscovery
	var xmppCapabilities: XMPPCapabilities
    var xmppCapabilitiesMyFeatures: Set<String> {
        didSet {
            xmppCapabilities.recollectMyCapabilities()
        }
    }
    
	var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	var xmppMessageArchiveManagement: XMPPMessageArchiveManagement
	var xmppRoomLightCoreDataStorage: XMPPRoomLightCoreDataStorage
	var xmppMessageDeliveryReceipts: XMPPMessageDeliveryReceipts

    var xmppOneToOneChat: XMPPOneToOneChat
    var xmppMUCLight: XMPPMUCLight
    let mucLightServiceName = "muclight.erlang-solutions.com" // TODO: service discovery
    var roomsLight = [XMPPRoomLight]() {
        willSet {
            for removedRoom in (roomsLight.filter { !newValue.contains($0) }) {
                xmppMessageArchiveManagement.removeDelegate(removedRoom)
                xmppRetransmission.removeDelegate(removedRoom)
                xmppOutOfBandMessaging.removeDelegate(removedRoom)
                removedRoom.removeDelegate(self)
                removedRoom.removeDelegate(self.xmppRoomLightCoreDataStorage)
                removedRoom.deactivate()
            }
        }
        didSet {
            for insertedRoom in (roomsLight.filter { !oldValue.contains($0) }) {
                insertedRoom.activate(xmppStream)
                insertedRoom.addDelegate(self, delegateQueue: .main)
                insertedRoom.addDelegate(self.xmppRoomLightCoreDataStorage, delegateQueue: insertedRoom.moduleQueue)
                xmppMessageArchiveManagement.addDelegate(insertedRoom, delegateQueue: insertedRoom.moduleQueue)
                xmppRetransmission.addDelegate(insertedRoom, delegateQueue: insertedRoom.moduleQueue)
                xmppOutOfBandMessaging.addDelegate(insertedRoom, delegateQueue: insertedRoom.moduleQueue)
            }
            roomListDelegate?.roomListDidChange(in: self)
        }
    }
    
    var xmppHttpFileUpload: XMPPHTTPFileUpload
    var xmppOutOfBandMessaging: XMPPOutOfBandMessaging
    var xmppOutOfBandMessagingStorage: XMPPOutOfBandMessagingFilesystemStorage
    
    var xmppMicrobloggingPubSub: XMPPPubSub
    var xmppPushNotificationsPubSub: XMPPPubSub
    
    let xmppPushNotifications: XMPPPushNotifications

    var password: String = ""
    
    var isXmppConnected = false
		
    weak var roomListDelegate: XMPPControllerRoomListDelegate?
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
		self.xmppCapabilities = XMPPCapabilities(capabilitiesStorage: XMPPCapabilitiesCoreDataStorage.sharedInstance())
		self.xmppCapabilities.autoFetchHashedCapabilities = true
		self.xmppCapabilities.autoFetchNonHashedCapabilities = false
        self.xmppCapabilities.myCapabilitiesNode = "https://github.com/esl/mangosta-ios"
        self.xmppCapabilitiesMyFeatures = []
		
        // PubSub
        self.xmppMicrobloggingPubSub = XMPPPubSub(serviceJID: nil, dispatchQueue: DispatchQueue.main)
        self.xmppMicrobloggingPubSub.pepNodes = [XMPPPubSubDefaultMicroblogNode]
        self.xmppPushNotificationsPubSub = MIMPushNotificationsPubSub(serviceJID: XMPPJID(string: "pubsub.erlang-solutions.com"))
        
		// Delivery Receips
		self.xmppMessageDeliveryReceipts = XMPPMessageDeliveryReceipts()
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryReceipts = true
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryRequests = true

		// Stream Managment
		self.xmppStreamManagement = XMPPStreamManagement(storage: XMPPStreamManagementDiscStorage())
		self.xmppStreamManagement.autoResume = true
        self.xmppRetransmission = XMPPRetransmission(dispatchQueue: .main, storage: XMPPRetransmissionUserDefaultsStorage())

        self.xmppMessageArchivingStorage = XMPPMessageArchivingCoreDataStorage()
        self.xmppMessageArchivingStorage.isOutOfBandMessageArchivingEnabled = true
        self.xmppRoomLightCoreDataStorage = XMPPRoomLightCoreDataStorage()
        
        let filteredMessageArchivingStorage = XMPPRetransmissionMessageArchivingStorageFilter(
            baseStorage: self.xmppMessageArchivingStorage,
            xmppRetransmission: self.xmppRetransmission
        )
        self.xmppOneToOneChat = XMPPOneToOneChat(messageArchivingStorage: filteredMessageArchivingStorage)
        self.xmppOneToOneChat.addDelegate(self.xmppMessageArchivingStorage, delegateQueue: self.xmppOneToOneChat.moduleQueue)
        self.xmppRetransmission.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)
        self.xmppMUCLight = XMPPMUCLight()
        
		self.xmppMessageArchiveManagement = XMPPMessageArchiveManagement()
        self.xmppMessageArchiveManagement.resultAutomaticPagingPageSize = NSNotFound
        self.xmppMessageArchiveManagement.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)
        
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

        self.xmppHttpFileUpload = XMPPHTTPFileUpload()
        self.xmppOutOfBandMessagingStorage = XMPPOutOfBandMessagingFilesystemStorage()
        self.xmppOutOfBandMessaging = XMPPOutOfBandMessaging(
            transferHandler: XMPPOutOfBandHTTPTransferHandler(
                urlSessionConfiguration: .default,
                xmpphttpFileUpload: self.xmppHttpFileUpload,
                uploadServiceJID: XMPPJID(string: "upload.erlang-solutions.com")    // TODO: discover service JID
            ),
            storage: self.xmppOutOfBandMessagingStorage
        )
        self.xmppOutOfBandMessaging.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)
        self.xmppOutOfBandMessaging.addDelegate(self.xmppMUCLight, delegateQueue: self.xmppMUCLight.moduleQueue)
        
		// Activate xmpp modules
		self.xmppReconnect.activate(self.xmppStream)
		self.xmppRoster.activate(self.xmppStream)
        self.xmppServiceDiscovery.activate(self.xmppStream)
		self.xmppCapabilities.activate(self.xmppStream)
        self.xmppMicrobloggingPubSub.activate(self.xmppStream)
        self.xmppPushNotificationsPubSub.activate(self.xmppStream)
		self.xmppMessageDeliveryReceipts.activate(self.xmppStream)
		self.xmppStreamManagement.activate(self.xmppStream)
        self.xmppRetransmission.activate(self.xmppStream)
		self.xmppMessageArchiveManagement.activate(self.xmppStream)
        self.xmppOneToOneChat.activate(self.xmppStream)
        self.xmppMUCLight.activate(self.xmppStream)
        self.xmppPushNotifications.activate(self.xmppStream)
        self.xmppOutOfBandMessaging.activate(self.xmppStream)
        self.xmppHttpFileUpload.activate(self.xmppStream)
		

		// Stream Settings
		self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed

		super.init()
		
        // Add delegates
		self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppServiceDiscovery.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppCapabilities.addDelegate(self, delegateQueue: DispatchQueue.main)
		self.xmppStreamManagement.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppMUCLight.addDelegate(self, delegateQueue: DispatchQueue.main)
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
        self.xmppReconnect.manualStart()
        
        return true
	}

	func disconnect() {
    
		self.goOffLine()
		self.xmppStream.disconnectAfterSending()
	}

    func retrieveMessageHistory(fromArchiveAt archiveJid: XMPPJID? = nil, startingAt startDate: Date? = nil, filteredBy filteringJid: XMPPJID? = nil) {
        let queryFields = [
            startDate.map { XMPPMessageArchiveManagement.field(withVar: "start", type: nil, andValue: ($0 as NSDate).xmppDateTimeString())!},
            filteringJid.map { XMPPMessageArchiveManagement.field(withVar: "with", type: nil, andValue: $0.bare())! }
            ].flatMap { $0 }
        
        xmppMessageArchiveManagement.retrieveMessageArchive(at: archiveJid ?? xmppStream.myJID.bare(), withFields: queryFields, with: XMPPResultSet(max: NSNotFound, after: ""))
    }

    func addRoom(withName roomName: String, initialOccupantJids: [XMPPJID]?) {
        let addedRoom = XMPPRoomLight(jid: XMPPJID(string: mucLightServiceName)!, roomname: roomName)
        addedRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
        addedRoom.activate(xmppStream)
        
        roomsLight.append(addedRoom)
        
        addedRoom.createRoomLight(withMembersJID: initialOccupantJids)
    }
    
    func enablePushNotifications(withDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02x", $0) } .joined()
        // TODO: [pwe] MIM currently requires explicit `topic` value to be provided when pushing using universal APNS certificates
        xmppPushNotifications.enable(withDeviceTokenString: deviceTokenString, customOptions: ["topic": Bundle.main.bundleIdentifier!])
    }
    
    func processPushNotification(from sender: XMPPJID) {
        if let room = (roomsLight.first { $0.roomJID.isEqual(to: sender, options: XMPPJIDCompareBare) }) {
            pushNotificationsDelegate?.xmppController(self, didReceiveGroupChatPushNotificationIn: room)
        } else if let contact = xmppRosterStorage.user(for: sender, xmppStream: xmppStream, managedObjectContext: xmppRosterStorage.managedObjectContext) {
            pushNotificationsDelegate?.xmppController(self, didReceivePrivateChatPushNotificationFromContact: contact)
        } else {
            pushNotificationsDelegate?.xmppController(self, didReceiveChatPushNotificationFromUnknownSenderWithJid: sender)
        }
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
        self.xmppMUCLight.removeDelegate(self)
        
		self.roomsLight.forEach { (roomLight) in
            self.xmppMessageArchiveManagement.removeDelegate(roomLight)
            self.xmppOutOfBandMessaging.removeDelegate(roomLight)
            roomLight.removeDelegate(self)
			roomLight.deactivate()
		}
        
		self.xmppReconnect.deactivate()
		self.xmppRoster.deactivate()
        self.xmppServiceDiscovery.deactivate()
		self.xmppCapabilities.deactivate()
        
        self.xmppMicrobloggingPubSub.deactivate()
        self.xmppPushNotificationsPubSub.deactivate()
		self.xmppMessageDeliveryReceipts.deactivate()
		self.xmppStreamManagement.deactivate()
        self.xmppRetransmission.deactivate()
		self.xmppMessageArchiveManagement.deactivate()
        self.xmppOneToOneChat.deactivate()
        self.xmppMUCLight.deactivate()
        self.xmppPushNotifications.deactivate()
        self.xmppOutOfBandMessaging.deactivate()
        self.xmppHttpFileUpload.deactivate()
        
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
		
        // TODO: initial presence should not be sent when the stream was resumed
        // However, microblog currently has no persistent storage and depends on
        // initial presence-based last item delivery each time the app is started
        self.goOnline()
        
        self.xmppServiceDiscovery.discoverInformationAbout(xmppStream.myJID.domain()) // TODO: xmppStream.myJID.bareJID()
        self.xmppMUCLight.discoverRooms(forServiceNamed: mucLightServiceName)
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
	}
	
	func goOffLine() {
		let presence = XMPPPresence(type: "unavailable")
		self.xmppStream.send(presence)
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

extension XMPPController: XMPPMUCLightDelegate {
    
    func xmppMUCLight(_ sender: XMPPMUCLight, didDiscoverRooms rooms: [DDXMLElement], forServiceNamed serviceName: String) {
        roomsLight = rooms.map { (rawElement) -> XMPPRoomLight in
            let rawJid = rawElement.attributeStringValue(forName: "jid")
            let rawName = rawElement.attributeStringValue(forName: "name")!
            let jid = XMPPJID(string: rawJid)!
            
            if let existingRoom = (roomsLight.first { $0.roomJID == jid}) {
                return existingRoom
            } else {
                let filteredRoomLightStorage = XMPPRetransmissionRoomLightStorageFilter(baseStorage: xmppRoomLightCoreDataStorage, xmppRetransmission: xmppRetransmission)
                return XMPPRoomLight(roomLightStorage: filteredRoomLightStorage, jid: jid, roomname: rawName, dispatchQueue: .main)
            }
        }
    }
    
    func xmppMUCLight(_ sender: XMPPMUCLight, changedAffiliation affiliation: String, roomJID: XMPPJID) {
        self.xmppMUCLight.discoverRooms(forServiceNamed: mucLightServiceName)
    }
}

extension XMPPController: XMPPRoomLightDelegate {
    
    func xmppRoomLight(_ sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
        xmppMUCLight.discoverRooms(forServiceNamed: mucLightServiceName)
    }
    
    func xmppRoomLight(_ sender: XMPPRoomLight, configurationChanged message: XMPPMessage) {
        roomListDelegate?.roomListDidChange(in: self)
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
    
    func xmppPubSub(_ sender: XMPPPubSub!, didReceive message: XMPPMessage!) {
        switch sender {
        case xmppMicrobloggingPubSub where message.isPubSubItemsEventMessage():
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
}

protocol XMPPControllerRoomListDelegate: class {
    
    func roomListDidChange(in controller: XMPPController)
}

protocol XMPPControllerPushNotificationsDelegate: class {
    
    func xmppControllerDidPrepareForPushNotificationsSupport(_ controller: XMPPController)
    func xmppController(_ controller: XMPPController, didReceivePrivateChatPushNotificationFromContact contact: XMPPUser)
    func xmppController(_ controller: XMPPController, didReceiveGroupChatPushNotificationIn room: XMPPRoomLight)
    func xmppController(_ controller: XMPPController, didReceiveChatPushNotificationFromUnknownSenderWithJid senderJid: XMPPJID)
}

protocol XMPPControllerMicrobloggingDelegate: class {
    
    func xmppController(_ controller: XMPPController, didPublishMicroblogEntryWithRequestID requestID: String)
    
    // TODO: [pwe] deliver error information
    func xmppController(_ controller: XMPPController, didFailToPublishMicroblogEntryWithRequestID requestID: String)
    
    func xmppController(_ controller: XMPPController, didReceiveMicroblogEntries microblogEntries: [DDXMLElement], from publisherJID: XMPPJID)
}
