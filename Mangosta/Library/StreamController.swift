//
//  StreamController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public class StreamController: NSObject, XMPPStreamDelegate {
	public struct CapabilityTypes: OptionSetType {
		public let rawValue: UInt8
		
		public init(rawValue: UInt8) {
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
	}
	let stream: XMPPStream
	let roster: XMPPRoster
	
	let rosterStorage: XMPPRosterCoreDataStorage
	var rosterCompletion: RosterCompletion?
	let streamCompletion: StreamCompletion
	
	let messageArchiving: XMPPMessageArchiving
	let messageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	
	var capabilityTypes: [CapabilityTypes]
	let capabilities: XMPPCapabilities
	let capabilitiesStorage: XMPPCapabilitiesCoreDataStorage
	
	let messageDeliveryReceipts: XMPPMessageDeliveryReceipts
	
	var messageCarbons: XMPPMessageCarbons
	
	public init(stream: XMPPStream, streamCompletion: StreamCompletion) {
		self.stream = stream
		self.streamCompletion = streamCompletion
		
		let rosterFileName = "roster-\(stream.myJID.user).sqlite"
		let messagingFileName = "messaging-\(stream.myJID.user).sqlite"
		
	XMPPRosterCoreDataStorage.performSelector(Selector("unregisterDatabaseFileName:"), withObject: rosterFileName)
		XMPPRosterCoreDataStorage.performSelector(Selector("unregisterDatabaseFileName:"), withObject: messagingFileName)

		self.rosterStorage = XMPPRosterCoreDataStorage(databaseFilename: rosterFileName, storeOptions: nil)
		
		self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
		
		self.messageArchivingStorage = XMPPMessageArchivingCoreDataStorage(databaseFilename: messagingFileName, storeOptions: nil)
		self.messageArchiving = XMPPMessageArchiving(messageArchivingStorage: self.messageArchivingStorage)
		
		self.capabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.capabilities = XMPPCapabilities(capabilitiesStorage: self.capabilitiesStorage)
		
		self.messageCarbons = XMPPMessageCarbons()
		
		self.messageDeliveryReceipts = XMPPMessageDeliveryReceipts()
		
		self.capabilityTypes = [.Roster, .MessageCarbons, .StreamManagement, .MessageDeliveryReceipts, .LastMessageCorrection, .ClientStateIndication, .MessageArchiving]
		
		super.init()
		
		self.finish()
	}
	
	private func finish() {
		if self.capabilityTypes.contains(.MessageDeliveryReceipts) {
			self.messageDeliveryReceipts.autoSendMessageDeliveryReceipts = true
			self.messageDeliveryReceipts.autoSendMessageDeliveryRequests = true
			self.messageDeliveryReceipts.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.messageDeliveryReceipts.activate(self.stream)
		}
		
		self.capabilities.autoFetchHashedCapabilities = true;
		self.capabilities.autoFetchNonHashedCapabilities = true;
		
		self.capabilities.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.capabilities.activate(self.stream)
		self.capabilities.fetchCapabilitiesForJID(self.stream.myJID)
		self.capabilities.recollectMyCapabilities()
		
		if self.capabilityTypes.contains(CapabilityTypes.Roster) {
			self.rosterStorage.autoRecreateDatabaseFile = true
			self.roster.activate(self.stream)
			self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			
			self.retrieveRoster() { (success, roster) in
				StreamManager.manager.sendPresence(true)
			}
		}
		
		if self.capabilityTypes.contains(CapabilityTypes.MessageArchiving) {
			self.messageArchiving.activate(self.stream)
			self.messageArchiving.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		}
		
		if self.capabilityTypes.contains(.MessageCarbons) {
			self.messageCarbons.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.messageCarbons.activate(self.stream)
		}
		
		
		
		self.streamCompletion(stream: self.stream)
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


//MARK: -
//MARK: XMPPMessageCarbonsDelegate
extension StreamController: XMPPMessageCarbonsDelegate {
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, didReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
	
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, willReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
}
