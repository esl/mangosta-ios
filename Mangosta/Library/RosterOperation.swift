//
//  RosterOperation.swift
//  SqorMobileiOS
//
//  Created by Andres on 9/10/15.
//  Copyright (c) 2015 Sqor, Inc. All rights reserved.
//

import UIKit
import XMPPFramework

class RosterOperation: AsyncOperation, XMPPRosterDelegate {
	var roster: XMPPRoster
	var rosterStorage: XMPPRosterCoreDataStorage
	var xmppStream: XMPPStream
	var completion: ((result: Bool, roster: XMPPRoster) -> Void)?
	
	private init(xmppStream: XMPPStream, rosterStorage: XMPPRosterCoreDataStorage) {
		self.xmppStream = xmppStream
		self.rosterStorage = rosterStorage
		self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
		
		super.init()
	}
	
	override func execute() {
		self.retrieveRoster()
	}
	
	class func retrieveRoster(xmppStream: XMPPStream, rosterStorage: XMPPRosterCoreDataStorage, completion: (result: Bool, roster: XMPPRoster) -> Void) -> RosterOperation {
		let rosterOperation = RosterOperation(xmppStream: xmppStream, rosterStorage: rosterStorage)
		rosterOperation.completion = completion
		return rosterOperation
	}
	
	private func retrieveRoster() {
		self.roster.activate(self.xmppStream)
		self.roster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.roster.autoFetchRoster = true
		self.roster.autoAcceptKnownPresenceSubscriptionRequests = true
		self.roster.fetchRoster()
	}
	
	// MARK: RosterDelegate
	func xmppRosterDidBeginPopulating(sender: XMPPRoster!, withVersion version: String!) {
		//print(version)
	}
	
	func xmppRosterDidEndPopulating(sender: XMPPRoster!) {
		print(self.rosterStorage.jidsForXMPPStream(self.xmppStream))
		if let completion = self.completion {
			self.roster.removeDelegate(self)
			completion(result: true, roster: self.roster)
		}
		
		finish()
	}
	
	func xmppRoster(sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) {
		print(item)
	}
}
