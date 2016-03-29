//
//  StreamManager+Public.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/22/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

extension StreamManager {
	public func addOperation(operation: NSOperation) {
		self.queue.addOperation(operation)
	}
	
	public func begin(authentication: AuthenticationModel, completion: VoidCompletion = {}) {
		self.connectCompletion = completion
		
		if self.isAttemptingConnection { return }
		
		
		
		self.authenticationModel = authentication
		
		self.isAttemptingConnection = true
		
		let hostName = (self.authenticationModel!.serverName != nil) ? self.authenticationModel!.serverName! : "192.168.100.109"

		let connectOperation = StreamOperation.createAndConnectStream(hostName, userJID: self.authenticationModel!.jid, password: self.authenticationModel!.password) { stream in
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
			StreamManager.manager.begin(self.authenticationModel!) { finished in
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
		self.streamController!.roster.removeDelegate(self)
		self.streamController?.rosterStorage.clearAllResourcesForXMPPStream(self.stream)
		//self.rosterStorage.clearAllResourcesForXMPPStream(self.stream)
		self.streamController = nil
		
		let disconnectOperation = StreamOperation.disconnectStream(self.stream) { (stream) in
			if let liveStream = self.stream {
				liveStream.disconnect()
			}
			
			self.stream = nil
		}
		self.addOperation(disconnectOperation)
		
	}
	
	public func sendPresence(available: Bool) {
		let verb = available ? "available" : "unavailable"
		let presence = XMPPPresence(type: verb)
		let priority = DDXMLElement(name: "priority", stringValue: "24")
		presence.addChild(priority)
		StreamManager.manager.sendElement(presence)
		NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notifications.RosterWasUpdated, object: nil)
		StreamManager.manager.clientState.changePresence(available ? ClientState.FeatureAvailability.Available : ClientState.FeatureAvailability.Unavailable)
	}
	
	public func isOnline() -> Bool {
		return self.clientState.presence == ClientState.FeatureAvailability.Available
	}
	
	public func isAvailable() -> Bool {
		return self.clientState.clientAvailability == ClientState.FeatureAvailability.Available
	}
	
	public func toggleCarbons(enabled: Bool) {
		if enabled {
			self.messageCarbons.enableMessageCarbons()
		} else {
			self.messageCarbons.disableMessageCarbons()
		}
	}
	
	public func messageCarbonsEnabled() -> Bool {
		return self.messageCarbons.messageCarbonsEnabled
	}
	
	public func becomeAvailable() {
		self.clientState.changeClientAvailability(ClientState.FeatureAvailability.Available)
		self.sendClientState(ClientState.FeatureAvailability.Available)
	}
	
	public func becomeUnavailable() {
		self.clientState.changeClientAvailability(ClientState.FeatureAvailability.Unavailable)
		self.sendClientState(ClientState.FeatureAvailability.Unavailable)
	}
}