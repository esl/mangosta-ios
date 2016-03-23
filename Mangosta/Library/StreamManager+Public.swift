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