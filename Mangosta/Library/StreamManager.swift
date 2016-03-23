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
	public static let manager = StreamManager()
	public var stream: XMPPStream!
	public var authenticationModel: AuthenticationModel?
	private var queue: NSOperationQueue
	private var connectionQueue: NSOperationQueue
	public var connectCompletion: VoidCompletion?
	private var isAttemptingConnection = false
	public var onlineJIDs : Set<String>
	public var carbonsEnabled = true
	public var fetchedResultsController: NSFetchedResultsController!
	public var roster: XMPPRoster?
	public var clientState = ClientState()
	
	var capabilities: XMPPCapabilities
	var capabilitiesStorage : XMPPCapabilitiesCoreDataStorage
	
	var roomStorage: XMPPRoomCoreDataStorage
	
	var rosterStorage: XMPPRosterCoreDataStorage
	
	var messageArchiving: XMPPMessageArchiving
	var messageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	
	var messageCarbons: XMPPMessageCarbons
	
	public func addOperation(operation: NSOperation) {
		self.queue.addOperation(operation)
	}
	
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
	
	public func begin(completion: VoidCompletion = {}) {
		self.connectCompletion = completion
		
		if self.isAttemptingConnection { return }
		
		guard let auth = AuthenticationModel.load() else {
			return
		}
		
		self.authenticationModel = auth
		
		self.isAttemptingConnection = true
		
		let connectOperation = StreamOperation.createAndConnectStream("192.168.100.109", userJID: auth.jid, password: auth.password) { (stream) -> Void in
			if let createdStream = stream {
				self.stream = createdStream
				self.stream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
				
				
				self.onConnectOrReconnect()
			} else {
				self.isAttemptingConnection = false
			}
			
			
		}
		self.connectionQueue.addOperation(connectOperation)
	}
	
	public func sendElement(element: DDXMLElement, completion: VoidCompletion = {}) {
		if StreamManager.manager.stream == nil {
			StreamManager.manager.begin() { finished in
				StreamManager.manager.stream.sendElement(element)
				completion()
			}
		} else {
			StreamManager.manager.stream.sendElement(element)
			completion()
		}
	}
	
	public func disconnect() {
		AuthenticationModel.remove()
		self.sendPresence(false)
		self.isAttemptingConnection = false
		self.roster?.removeDelegate(self)
		self.rosterStorage.clearAllResourcesForXMPPStream(self.stream)
		self.roster = nil
		
		if let liveStream = self.stream {
			liveStream.disconnect()
		}
		
		self.stream = nil
	}
	
	private func onConnectOrReconnect() {
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
	
	private func rosterFileDirectoryPath() -> String {
		let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
		let filename = self.stream.myJID.bare()
		let finalPath = path.stringByAppendingPathComponent(filename)
		
		return finalPath
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

extension StreamManager: XMPPRosterDelegate {
	// MARK: RosterDelegate
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

extension StreamManager: XMPPMessageCarbonsDelegate {
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, didReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
	
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, willReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
}

