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
		
		super.init()
	}
	
	public func finish() {
		self.roster.activate(self.stream)
		self.messageArchiving.activate(self.stream)
		
		self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.messageArchiving.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		self.retrieveRoster() { (success, roster) in
			StreamManager.manager.sendPresence(true)
		}
		self.streamCompletion(stream: self.stream)
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