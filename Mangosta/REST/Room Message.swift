//
//  RoomMessage.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

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

	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			from = dictionary["from"] as? String,
			user = dictionary["user"] as? String,
			body = dictionary["body"] as? String,
			timestamp = dictionary["timestamp"] as? String,
			type = dictionary["type"] as? String,
			affiliation = dictionary["affiliation"] as? String
			else { throw JaymeError.ParsingError }
		self.id = id
		self.from = from
		self.user = user
		self.body = body
		self.timestamp = timestamp
		self.type = type
		self.affiliation = affiliation
	}
	var dictionaryValue: [String: AnyObject] {
		return [
			"id": self.id,
			"from": self.from,
			"user": self.user,
			"body": self.body,
			"affiliation": self.affiliation
		]
	}

}
