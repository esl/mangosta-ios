//
//  StreamController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public class StreamController: NSObject {
	public struct CapabilityTypes: OptionSetType {
		public let rawValue: UInt16
		
		public init(rawValue: UInt16) {
			self.rawValue = rawValue
		}
		public static let Roster = CapabilityTypes(rawValue: 1 << 0)
		public static let MessageCarbons = CapabilityTypes(rawValue: 1 << 1)
		public static let StreamManagement = CapabilityTypes(rawValue: 1 << 2)
		public static let MessageDeliveryReceipts = CapabilityTypes(rawValue: 1 << 3)
		public static let LastMessageCorrection = CapabilityTypes(rawValue: 1 << 4)
		public static let ClientStateIndication = CapabilityTypes(rawValue: 1 << 5)
		public static let MessageArchiving = CapabilityTypes(rawValue: 1 << 6)
		public static let PushNotifications = CapabilityTypes(rawValue: 1 << 7)
		public static let MessageArchiveManagement = CapabilityTypes(rawValue: 1 << 8)
		public static let MUC = CapabilityTypes(rawValue: 1 << 9)
	}
	let stream: XMPPStream
	let roster: XMPPRoster
	
	let rosterStorage: XMPPRosterCoreDataStorage
	var rosterCompletion: RosterCompletion?
	
	let mucStorage: XMPPMUCCoreDataStorage
	let xmppMUCStorer: XMPPMUCStorer

	let streamCompletion: StreamCompletion
	
	
	let messageArchiving: XMPPMessageArchiving
	let messageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	
	let messageArchiveManagement: XMPPMessageArchiveManagement
	
	let streamManagement: XMPPStreamManagement
	let streamManagementStorage: XMPPStreamManagementMemoryStorage
	
	var capabilityTypes: [CapabilityTypes]
	let capabilities: XMPPCapabilities
	let capabilitiesStorage: XMPPCapabilitiesCoreDataStorage
	
	let serviceDiscovery: XMPPServiceDiscovery
	
	let messageDeliveryReceipts: XMPPMessageDeliveryReceipts
	
	var messageCarbons: XMPPMessageCarbons
	
	public init(stream: XMPPStream, streamCompletion: StreamCompletion) {
		self.stream = stream
		self.streamCompletion = streamCompletion
		
		let rosterFileName = "roster-\(stream.myJID.user).sqlite"
		let messagingFileName = "messaging-\(stream.myJID.user).sqlite"
		let roomFileName = "rooms-\(stream.myJID.user).sqlite"
		
		XMPPRosterCoreDataStorage.performSelector(Selector("unregisterDatabaseFileName:"), withObject: rosterFileName)
		XMPPRosterCoreDataStorage.performSelector(Selector("unregisterDatabaseFileName:"), withObject: messagingFileName)

		self.rosterStorage = XMPPRosterCoreDataStorage(databaseFilename: rosterFileName, storeOptions: nil)
		self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
		
		self.mucStorage = XMPPMUCCoreDataStorage(databaseFilename: roomFileName, storeOptions: nil)
		self.xmppMUCStorer = XMPPMUCStorer(roomStorage: self.mucStorage)
		
		self.messageArchivingStorage = XMPPMessageArchivingCoreDataStorage(databaseFilename: messagingFileName, storeOptions: nil)
		self.messageArchiving = XMPPMessageArchiving(messageArchivingStorage: self.messageArchivingStorage)
		
		self.messageArchiveManagement = XMPPMessageArchiveManagement(dispatchQueue: dispatch_get_main_queue())
		
		self.capabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.capabilities = XMPPCapabilities(capabilitiesStorage: self.capabilitiesStorage)
		
		self.serviceDiscovery = XMPPServiceDiscovery()
		
		self.messageCarbons = XMPPMessageCarbons()
		
		self.messageDeliveryReceipts = XMPPMessageDeliveryReceipts()
		
		self.capabilityTypes = [.Roster, .MessageCarbons, .StreamManagement, .MessageDeliveryReceipts, .LastMessageCorrection, .ClientStateIndication, .MessageArchiving, .MessageArchiveManagement, .MUC]
		
		self.streamManagementStorage = XMPPStreamManagementMemoryStorage()
		self.streamManagement = XMPPStreamManagement(storage: self.streamManagementStorage)
		
		super.init()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)

		self.finish()
	}
	
	private func finish() {
		
		self.xmppMUCStorer.activate(self.stream)
		self.stream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		if self.capabilityTypes.contains(.MessageDeliveryReceipts) {
			self.enableCapability(.MessageDeliveryReceipts)
		}
		
		self.capabilities.autoFetchHashedCapabilities = true;
		self.capabilities.autoFetchNonHashedCapabilities = true;
		
		self.capabilities.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.capabilities.activate(self.stream)
		self.capabilities.fetchCapabilitiesForJID(self.stream.myJID.domainJID())
		self.capabilities.recollectMyCapabilities()
		
		self.serviceDiscovery.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.serviceDiscovery.activate(self.stream)
		self.serviceDiscovery.fetchItemsForJID(self.stream.myJID.domainJID())
		
		if self.capabilityTypes.contains(CapabilityTypes.Roster) {
			self.enableCapability(.Roster)
			
			self.retrieveRoster() { (success, roster) in
				StreamManager.manager.sendPresence(true)
			}
		}
		
		if self.capabilityTypes.contains(CapabilityTypes.MessageArchiving) {
			self.enableCapability(.MessageArchiving)
		}
		
		if self.capabilityTypes.contains(.MessageCarbons) {
			self.messageCarbons.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.messageCarbons.activate(self.stream)
			self.enableCapability(.MessageCarbons)
		}
		
		if self.capabilityTypes.contains(.MUC) {
			let roomListOperation = XMPPMUCOperation.retrieveRooms() { rooms in
				print(rooms)
			}
			
			StreamManager.manager.addOperation(roomListOperation)
		}
		
		if self.capabilityTypes.contains(.StreamManagement) {
			self.streamManagement.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.streamManagement.activate(self.stream)
			self.streamManagement.enableStreamManagementWithResumption(true, maxTimeout: 500)
			self.streamManagement.autoResume = true
		}
		
		if self.capabilityTypes.contains(.MessageArchiveManagement) {
			self.messageArchiveManagement.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.messageArchiveManagement.activate(self.stream)
			self.messageArchiveManagement.retrieveMessageArchive()
		}

		self.streamCompletion(stream: self.stream)
	}
	
	public func enableCapability(capability: CapabilityTypes) {
		
		switch capability {
		case CapabilityTypes.ClientStateIndication:
			break
		case CapabilityTypes.LastMessageCorrection:
			break
		case CapabilityTypes.MessageArchiving:
			self.messageArchiving.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.messageArchiving.activate(self.stream)
		case CapabilityTypes.MessageCarbons:
			self.messageCarbons.autoEnableMessageCarbons = true
			self.messageCarbons.enableMessageCarbons()
		case CapabilityTypes.MessageDeliveryReceipts:
			self.messageDeliveryReceipts.autoSendMessageDeliveryReceipts = true
			self.messageDeliveryReceipts.autoSendMessageDeliveryRequests = true
			self.messageDeliveryReceipts.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.messageDeliveryReceipts.activate(self.stream)
		case CapabilityTypes.PushNotifications:
			break
		case CapabilityTypes.Roster:
			self.rosterStorage.autoRecreateDatabaseFile = true
			self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.roster.activate(self.stream)
		case CapabilityTypes.StreamManagement:
			break
		default:
			()
		}
		if !self.capabilityTypes.contains(capability) {
			self.capabilityTypes.append(capability)
		}
	}
	
	public func disableCapability(capability: CapabilityTypes) {
		switch capability {
		case CapabilityTypes.ClientStateIndication:
			break
		case CapabilityTypes.LastMessageCorrection:
			break
		case CapabilityTypes.MessageArchiving:
			self.messageArchiving.removeDelegate(self)
			self.messageArchiving.deactivate()
		case CapabilityTypes.MessageCarbons:
			self.messageCarbons.autoEnableMessageCarbons = false
			//self.messageCarbons.setValue(false, forKey: "messageCarbonsEnabled")
			self.messageCarbons.disableMessageCarbons()
			//self.messageCarbons.removeDelegate(self)
			//self.messageCarbons.deactivate()
		case CapabilityTypes.MessageDeliveryReceipts:
			self.messageDeliveryReceipts.removeDelegate(self)
			self.messageDeliveryReceipts.deactivate()
		case CapabilityTypes.PushNotifications:
			break
		case CapabilityTypes.Roster:
			self.roster.removeDelegate(self)
			self.roster.deactivate()
		case CapabilityTypes.StreamManagement:
			break
		default:
			()
		}
		if self.capabilityTypes.contains(capability) {
			if let index = self.capabilityTypes.indexOf(capability) {
				self.capabilityTypes.removeAtIndex(index)
			}
		}
	}
	
	public func retrieveRoster(completion: RosterCompletion) {
		self.rosterCompletion = completion
		self.roster.autoFetchRoster = true
		self.roster.autoAcceptKnownPresenceSubscriptionRequests = true
		self.roster.fetchRoster()
	}
}

extension StreamController: XMPPRosterDelegate {
	// MARK: RosterDelegate
	public func xmppRosterDidBeginPopulating(sender: XMPPRoster!, withVersion version: String!) {
		//print(version)
	}
	
	public func xmppRosterDidEndPopulating(sender: XMPPRoster!) {
		print(self.rosterStorage.jidsForXMPPStream(self.stream))
		if let completion = self.rosterCompletion {
			self.roster.removeDelegate(self)
			NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notifications.RosterWasUpdated, object: nil)
			completion(result: true, roster: self.roster)
		}
	}
	
	public func xmppRoster(sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) {
		print(item)
	}
}

//MARK: -
//MARK: XMPPCapabilitiesDelegate
extension StreamController: XMPPCapabilitiesDelegate {
	public func xmppCapabilities(sender: XMPPCapabilities!, collectingMyCapabilities query: DDXMLElement!) {
		print(query)
	}
	public func xmppCapabilities(sender: XMPPCapabilities!, didDiscoverCapabilities caps: DDXMLElement!, forJID jid: XMPPJID!) {
		print(caps)
	}

	public func myFeaturesForXMPPCapabilities(sender: XMPPCapabilities!) -> [AnyObject]! {
		if self.capabilitiesStorage.areCapabilitiesKnownForJID(self.stream.myJID, xmppStream: self.stream) {
			let val = self.capabilitiesStorage.capabilitiesForJID(self.stream.myJID, xmppStream: self.stream)
			return [val]
		} else {
			return []
		}
	}
}


//MARK:
extension StreamController: XMPPStreamDelegate {
	
	public func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
		print(message)
	}
}

//MARK:
extension StreamController: XMPPRoomDelegate {
	
	
}


//MARK: -
//MARK: XMPPMessageCarbonsDelegate
extension StreamController: XMPPMessageCarbonsDelegate {
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, didReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		self.messageArchiving.xmppMessageArchivingStorage.archiveMessage(message, outgoing: isOutgoing, xmppStream: self.stream)
	}
	
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, willReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
}

//MARK: -
//MARK: XMPPMessageArchiveManagemet
extension StreamController: XMPPMessageArchiveManagementDelegate {
	public func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMessageCount messageCount: Int) {
		print("Got this message count: \(messageCount)")
	}
	public func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessages messageCount: Int) {
		print("finished retrieving messages: \(messageCount)")
	}
	public func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMessage message: XMPPMessage!) {
		let outgoing = message.from().bare() == self.stream.myJID.bare()
		self.messageArchiving.xmppMessageArchivingStorage.archiveMessage(message, outgoing: outgoing, xmppStream: self.stream)
	}
}

//MARK: -
//MARK: XMPPStreamManagementDelegate
extension StreamController: XMPPStreamManagementDelegate {
	public func xmppStreamManagement(sender: XMPPStreamManagement!, wasEnabled enabled: DDXMLElement!) {
		print("Stream Management Enabled")
	}
	
	public func xmppStreamManagement(sender: XMPPStreamManagement!, wasNotEnabled failed: DDXMLElement!) {
		print("Stream Management was not enabled")
	}
}

//MARK: -
//MARK: UIApplicationDelegate
extension StreamController: UIApplicationDelegate {
	
	public func applicationWillResignActive(application: UIApplication) {
		self.saveStreamManagementState()
	}
	
	public func applicationWillEnterForeground(application: UIApplication) {
		self.streamManagement.loadState()
		self.streamManagement.requestAck()
	}
	
	private func saveStreamManagementState() {
		self.streamManagement.saveState()
	}
}
