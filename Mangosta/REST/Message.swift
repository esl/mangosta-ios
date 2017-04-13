//
//  Message.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//


import Foundation
import Jayme

struct Message: Identifiable {

	let id: String
	let to: String
	let from: String
	let body: String
	let timestamp: CLong
}

extension Message: DictionaryInitializable, DictionaryRepresentable {
	
	init(dictionary: [String: Any]) throws {
		guard let
			id = dictionary["id"] as? String,
			let to = dictionary["to"] as? String,
			let body = dictionary["body"] as? String,
			let from = dictionary["from"] as? String,
			let timestamp = dictionary["timestamp"] as? CLong
			else { throw JaymeError.parsingError }
		self.id = id
		self.to = to
		self.from = from
		self.body = body
		self.timestamp = timestamp
	}

	
	var dictionaryValue: [String: Any] {
		return [
			"to": self.to as Any,
			"body": self.body as Any
		]
	}

}
