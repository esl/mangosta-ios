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