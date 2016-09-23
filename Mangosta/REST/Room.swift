//
//  Room.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

struct Room: Identifiable {
	let id: String
	let roomName: String
}

extension Room: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			roomName = dictionary["roomName"] as? String
			else { throw JaymeError.ParsingError }
		self.id = id
		self.roomName = roomName
	}

	var dictionaryValue: [String: AnyObject] {
		return [
			"id": self.id,
			"roomName": self.roomName
		]
	}
}
