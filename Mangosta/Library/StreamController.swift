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
	let stream: XMPPStream
	let roster: XMPPRoster
	let authenticationModel: AuthenticationModel
	
	let rosterStorage: XMPPRosterCoreDataStorage
	var rosterCompletion: RosterCompletion?
	let streamCompletion: StreamCompletion
	
	let messageArchiving: XMPPMessageArchiving
	let messageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	
	let capabilities: XMPPCapabilities
	let capabilitiesStorage: XMPPCapabilitiesCoreDataStorage
	
	var messageCarbons: XMPPMessageCarbons
	
	public init(authentication: AuthenticationModel, stream: XMPPStream, streamCompletion: StreamCompletion) {
		self.stream = stream
		self.authenticationModel = authentication
		self.streamCompletion = streamCompletion
		
		let rosterFileName = "roster-\(stream.myJID.user).sqlite"
		let messagingFileName = "messaging-\(stream.myJID.user).sqlite"
		
		self.rosterStorage = XMPPRosterCoreDataStorage(databaseFilename: rosterFileName, storeOptions: nil)
		self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
		
		self.messageArchivingStorage = XMPPMessageArchivingCoreDataStorage(databaseFilename: messagingFileName, storeOptions: nil)
		self.messageArchiving = XMPPMessageArchiving(messageArchivingStorage: self.messageArchivingStorage)
		
		self.capabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.capabilities = XMPPCapabilities(capabilitiesStorage: self.capabilitiesStorage)
		
		self.messageCarbons = XMPPMessageCarbons()
		
		super.init()
		
		self.finish()
	}
	
	public func finish() {
		self.roster.activate(self.stream)
		self.messageArchiving.activate(self.stream)
		
		self.capabilities.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.capabilities.activate(self.stream)
		self.capabilities.recollectMyCapabilities()
		
		self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.messageArchiving.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		self.retrieveRoster() { (success, roster) in
			StreamManager.manager.sendPresence(true)
		}
		self.streamCompletion(stream: self.stream)
		
		self.messageCarbons.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.messageCarbons.activate(self.stream)
	}
	
	public func retrieveRoster(completion: RosterCompletion) {
		self.rosterCompletion = completion
		//self.roster.activate(self.stream)
		//self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
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
