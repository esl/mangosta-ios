//
//  User.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

struct User: Identifiable {
	let id: String
	let jid: String
}

extension User: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			jid = dictionary["jid"] as? String
			else { throw JaymeError.ParsingError }
		self.id = id
		self.jid = jid
	}


	var dictionaryValue: [String: AnyObject] {
		return [
			"id": self.id,
			"jid": self.jid
		]
	}

}
