//
//  JID.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

struct JID: Identifiable {
	let id: String
	let JID: String
}

extension JID: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: AnyObject]) throws {
		guard let
			id = dictionary["id"] as? String,
			JID = dictionary["JID"] as? String
			else { throw JaymeError.ParsingError }
		self.id = id
		self.JID = JID
	}

	var dictionaryValue: [String: AnyObject] {
		return [
			"id": self.id,
			"JID": self.JID
		]
	}
}
