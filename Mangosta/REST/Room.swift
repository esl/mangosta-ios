//
//  Room.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import Jayme

struct Room: Identifiable {
	let id: String
	let subject: String
	let name: String
	let participants: [String:String]
}

extension Room: DictionaryInitializable, DictionaryRepresentable {

    init(dictionary: [String: Any]) throws {
		guard let
			id = dictionary["id"] as? String,
			let subject = dictionary["subject"] as? String,
			let name = dictionary["name"] as? String,
			let participants = dictionary["participants"] as? [String:String]
			else { throw JaymeError.parsingError }
		self.id = id
		self.subject = subject
		self.name = name
		self.participants = participants
	}

    var dictionaryValue: [String: Any] {
		return [
			"subject": self.subject as Any, // FIXME: needs to be implemented at server side.
			"name": self.name as Any
		]
	}
}
