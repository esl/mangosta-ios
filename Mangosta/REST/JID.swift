//
//  JID.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import Jayme

struct JID: Identifiable {
	let id: String
	let JID: String
}

extension JID: DictionaryInitializable, DictionaryRepresentable {

	init(dictionary: [String: Any]) throws {
		guard let
			id = dictionary["id"] as? String,
			let JID = dictionary["JID"] as? String
			else { throw JaymeError.parsingError }
		self.id = id
		self.JID = JID
	}

    var dictionaryValue: [String: Any] {
		return [
			"id": self.id as Any,
			"JID": self.JID as Any
		]
	}
}
