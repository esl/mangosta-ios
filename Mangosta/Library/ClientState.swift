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
		case Available
		case Unavailable
	}
	
	var presence: FeatureAvailability = FeatureAvailability.Unavailable
	var clientAvailability: FeatureAvailability = FeatureAvailability.Unavailable
	
	mutating func changePresence(newPresence: FeatureAvailability) {
		self.presence = newPresence
	}
	
	mutating func changeClientAvailability(newAvailability: FeatureAvailability) {
		self.clientAvailability = newAvailability
	}
}
