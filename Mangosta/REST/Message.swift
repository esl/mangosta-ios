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
	let from: String
	let to: String
	let body: String
}

extension Message: DictionaryInitializable, DictionaryRepresentable {
	
	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			from = dictionary["from"] as? String,
			to = dictionary["to"] as? String,
			body = dictionary["body"] as? String
			else { throw JaymeError.ParsingError }
		self.id = id
		self.from = from
		self.to = to
		self.body = body
	}

	
	var dictionaryValue: [String: AnyObject] {
		return [
			"id": self.id,
			"from": self.from,
			"to": self.to,
			"body": self.body
		]
	}

}
