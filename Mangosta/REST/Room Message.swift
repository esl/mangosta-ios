//
//  RoomMessage.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import Jayme

struct RoomMessage: Identifiable {
	let id: String
	let from: String
	let user: String
	let body: String
	let timestamp: String
	let type: String
	let affiliation: String
}

extension RoomMessage: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: Any]) throws {
		guard let
			id = dictionary["id"] as? String,
			let from = dictionary["from"] as? String,
			let user = dictionary["user"] as? String,
			let body = dictionary["body"] as? String,
			let timestamp = dictionary["timestamp"] as? String,
			let type = dictionary["type"] as? String,
			let affiliation = dictionary["affiliation"] as? String
			else { throw JaymeError.parsingError }
		self.id = id
		self.from = from
		self.user = user
		self.body = body
		self.timestamp = timestamp
		self.type = type
		self.affiliation = affiliation
	}
    var dictionaryValue: [String: Any] {
		return [
			"id": self.id as Any,
			"from": self.from as Any,
			"user": self.user as Any,
			"body": self.body as Any,
			"affiliation": self.affiliation as Any
		]
	}

}
