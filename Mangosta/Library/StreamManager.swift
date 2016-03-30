//
//  StateManager.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/14/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public class StreamManager : NSObject {
	//MARK: Private variables
	private var capabilities: XMPPCapabilities
	private var capabilitiesStorage : XMPPCapabilitiesCoreDataStorage
	
	//MARK: Public variables
	public static let manager = StreamManager()
	public var stream: XMPPStream!
	public var authenticationModel: AuthenticationModel?
	public var connectCompletion: VoidCompletion?
	public var onlineJIDs : Set<String>
	public var carbonsEnabled = true
	public var fetchedResultsController: NSFetchedResultsController!
	public var roster: XMPPRoster?
	public var clientState = ClientState()
	
	//MARK: Internal Variables
	internal var isAttemptingConnection = false
	internal var queue: NSOperationQueue
	internal var connectionQueue: NSOperationQueue
	internal var messageArchiving: XMPPMessageArchiving
	internal var roomStorage: XMPPRoomCoreDataStorage
	internal var rosterStorage: XMPPRosterCoreDataStorage
	internal var messageCarbons: XMPPMessageCarbons
	internal var messageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	
	//MARK: Private functions
	private override init() {
		self.queue = NSOperationQueue()
		self.queue.maxConcurrentOperationCount = 1
		self.queue.suspended = true
		
		self.connectionQueue = NSOperationQueue()
		self.connectionQueue.maxConcurrentOperationCount = 2
		
		self.capabilitiesStorage = XMPPCapabilitiesCoreDataStorage.sharedInstance()
		self.roomStorage = XMPPRoomCoreDataStorage.sharedInstance()
		self.rosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
		self.messageArchivingStorage = XMPPMessageArchivingCoreDataStorage()
		
		self.capabilities = XMPPCapabilities(capabilitiesStorage: self.capabilitiesStorage)
		self.messageArchiving = XMPPMessageArchiving(messageArchivingStorage: self.messageArchivingStorage)
		
		self.messageCarbons = XMPPMessageCarbons()
		//self.capabilities.autoFetchMyServerCapabilities = true
		//self.capabilities.autoFetchHashedCapabilities = true
		
		
		self.onlineJIDs = []
		
		super.init()
		
		self.fetchedResultsController = self.createFetchedResultsControllerForAllMessages()
	}
	
	//MARK: Internal functions
	internal func onConnectOrReconnect() {
		self.isAttemptingConnection = false
		self.queue.suspended = false
		
		let rosterOperation = RosterOperation.retrieveRoster(self.stream, roster: self.roster, rosterStorage:  self.rosterStorage) { completed, roster in
			print("Got roster")

			self.roster = roster
			if let myRoster = self.roster {
				myRoster.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			}
		}
		
		StreamManager.manager.addOperation(rosterOperation)
		
		self.capabilities.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.messageCarbons.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.capabilities.activate(self.stream)
		self.capabilities.recollectMyCapabilities()
		
		self.messageArchiving.activate(self.stream)
		
		self.messageCarbons.activate(self.stream)
		
		self.carbonsEnabled = self.messageCarbons.messageCarbonsEnabled
		
		let roomListOperation = RoomListOperation.retrieveRooms() { response in
			
		}
		StreamManager.manager.addOperation(roomListOperation)
		
		self.becomeAvailable()
		
		if let completion = self.connectCompletion {
			completion()
		}
		self.connectCompletion = nil
	}
	
	internal func sendClientState(clientState: ClientState.FeatureAvailability) {
		var element: NSXMLElement
		if clientState == ClientState.FeatureAvailability.Available {
			element = NSXMLElement.indicateActiveElement()
		} else {
			element = NSXMLElement.indicateInactiveElement()
		}
		self.sendElement(element)
	}
}

//MARK: -
//MARK: XMPPStreamDelegate
extension StreamManager : XMPPStreamDelegate {
	public func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
		print(message)
	}
	
	public func xmppStreamDidConnect(sender: XMPPStream!) {
		if let stream = sender {
			let authenticationOperation = StreamOperation.authenticateStream(stream, password: self.authenticationModel!.password) { (stream) -> Void in
				if let _ = stream {
					self.onConnectOrReconnect()
				}
			}
			self.connectionQueue.addOperation(authenticationOperation)
		}
	}
	
	public func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
		self.queue.suspended = true
	}
	
	//MARK: Presence
	public func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
		//if let p = presence, let user = p.from().user where user != self.authenticationModel?.jid.user {
		if let p = presence, let user = p.from().user {
			if p.type() == "available" {
				self.onlineJIDs.insert(user)
			} else {
				self.onlineJIDs.remove(user)
			}
		}
	}
	
	public func xmppStream(sender: XMPPStream!, didReceiveIQ iq: XMPPIQ!) -> Bool {
		print(iq)
		
		return true
	}
	
	public func xmppStream(sender: XMPPStream!, didSendCustomElement element: DDXMLElement!) {
		print("sent custom element: \(element)")
	}
	
	public func xmppStream(sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
		print(error)
	}
	
	public func sendPresence(available: Bool) {
		let verb = available ? "available" : "unavailable"
		let presence = XMPPPresence(type: verb)
		let priority = DDXMLElement(name: "priority", stringValue: "24")
		presence.addChild(priority)
		StreamManager.manager.sendElement(presence)
		StreamManager.manager.clientState.changePresence(available ? ClientState.FeatureAvailability.Available : ClientState.FeatureAvailability.Unavailable)
	}
	
	//MARK: Room stuff
	public func createFetchedResultsControllerForAllMessages() -> NSFetchedResultsController {
		let context = self.roomStorage.mainThreadManagedObjectContext
		let entity = self.roomStorage.occupantEntity(context)
		let sd1 = NSSortDescriptor(key: "createdAt", ascending: true)
		let fetchRequest = NSFetchRequest()
		fetchRequest.entity = entity
		fetchRequest.fetchBatchSize = 1
		fetchRequest.sortDescriptors = [sd1]
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		return fetchedResultsController
	}
	
	public func roomForJid(jid: XMPPJID) -> XMPPRoom? {
		try! self.fetchedResultsController.performFetch()
		if let rooms = self.fetchedResultsController.fetchedObjects as? [XMPPRoom] {
			let fetchedRoom = rooms.filter { $0.roomJID.bare() == jid.bare() }.first
			return fetchedRoom
		}
		return nil
	}
}

//MARK: -
//MARK: RosterDelegate
extension StreamManager: XMPPRosterDelegate {
	public func xmppRosterDidBeginPopulating(sender: XMPPRoster!, withVersion version: String!) {
		//print(version)
	}
	
	public func xmppRosterDidEndPopulating(sender: XMPPRoster!) {
		print("End Populating")
	}
	
	public func xmppRoster(sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) {
		print(item)
	}
}

//MARK: -
//MARK: XMPPCapabilitiesDelegate
extension StreamManager : XMPPCapabilitiesDelegate {
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
extension StreamManager: XMPPMessageCarbonsDelegate {
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, didReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
	
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, willReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
}

