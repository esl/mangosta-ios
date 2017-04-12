//
//  ClientState.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/22/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

public struct ClientState {
	public enum FeatureAvailability {
		case available
		case unavailable
	}
	
	var presence: FeatureAvailability = FeatureAvailability.unavailable
	var clientAvailability: FeatureAvailability = FeatureAvailability.unavailable
	
	mutating func changePresence(_ newPresence: FeatureAvailability) {
		self.presence = newPresence
	}
	
	mutating func changeClientAvailability(_ newAvailability: FeatureAvailability) {
		self.clientAvailability = newAvailability
	}
}
