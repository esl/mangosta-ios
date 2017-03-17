//
//  User.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import Jayme

struct User: Identifiable {
	let id: String
	let jid: String
}

extension User: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: Any]) throws {
		guard let
			id = dictionary["id"] as? String,
			let jid = dictionary["jid"] as? String
			else { throw JaymeError.parsingError }
		self.id = id
		self.jid = jid
	}


	var dictionaryValue: [String: Any] {
		return [
			"id": self.id as Any,
			"jid": self.jid as Any
		]
	}

}
