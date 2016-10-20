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
	let subject: String
	let name: String
	let participants: [String:String]
}

extension Room: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			subject = dictionary["subject"] as? String,
			name = dictionary["name"] as? String,
			participants = dictionary["participants"] as? [String:String]
			else { throw JaymeError.ParsingError }
		self.id = id
		self.subject = subject
		self.name = name
		self.participants = participants
	}

	var dictionaryValue: [String: AnyObject] {
		return [
			"subject": self.subject, // FIXME: needs to be implemented at server side.
			"name": self.name
		]
	}
}
