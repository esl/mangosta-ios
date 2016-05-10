//
//  RosterOperation.swift
//  Mangosta
//
//  Created by Andres Canal on 4/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class RosterOperation: AsyncOperation, XMPPRosterDelegate {
	var roster: XMPPRoster
	var rosterStorage: XMPPRosterCoreDataStorage
	var xmppStream: XMPPStream
	var completion: ((result: Bool, roster: XMPPRoster) -> Void)?
	
	private init(xmppStream: XMPPStream, roster: XMPPRoster?, rosterStorage: XMPPRosterCoreDataStorage) {
		self.xmppStream = xmppStream
		self.rosterStorage = rosterStorage
		if roster == nil {
			self.roster = XMPPRoster(rosterStorage: self.rosterStorage)
		} else {
			self.roster = roster!
		}
		
		super.init()
	}
	
	override func execute() {
		self.retrieveRoster()
	}
	
	class func retrieveRoster(xmppStream: XMPPStream, roster: XMPPRoster?, rosterStorage: XMPPRosterCoreDataStorage, completion: (result: Bool, roster: XMPPRoster) -> Void) -> RosterOperation {
		let rosterOperation = RosterOperation(xmppStream: xmppStream, roster: roster, rosterStorage: rosterStorage)
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

	}
	
	func xmppRosterDidEndPopulating(sender: XMPPRoster!) {
		if let completion = self.completion {
			self.roster.removeDelegate(self)
			completion(result: true, roster: self.roster)
		}
		
		self.finish()
	}
	
	func xmppRoster(sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) {

	}
}
