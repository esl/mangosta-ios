//
//  Message.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//


import Foundation

struct Message: Identifiable {

	let id: String
	let to: String
	let from: String
	let body: String
	let timestamp: CLong
}

extension Message: DictionaryInitializable, DictionaryRepresentable {
	
	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			to = dictionary["to"] as? String,
			body = dictionary["body"] as? String,
			from = dictionary["from"] as? String,
			timestamp = dictionary["timestamp"] as? CLong
			else { throw JaymeError.ParsingError }
		self.id = id
		self.to = to
		self.from = from
		self.body = body
		self.timestamp = timestamp
	}

	
	var dictionaryValue: [String: AnyObject] {
		return [
			"to": self.to,
			"body": self.body
		]
	}

}
