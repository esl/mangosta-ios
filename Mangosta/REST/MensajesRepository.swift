//
//  MensajesRepository.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Jayme

class MessageRepository: CRUDRepository {
	
	typealias EntityType = Message
	let backend = URLSessionBackend.MongooseREST()
	let name = "messages"
	
	func sendMessage(_ entity: EntityType) -> Future<Void, JaymeError> {
		let path = self.name
		return self.backend.future(path: path, method: .POST, parameters: entity.dictionaryValue)
			.map { _ in return }
	}

	func getNMessages(_ limit: NSNumber?, before: NSNumber?) -> Future<[EntityType], JaymeError> {
		let path = self.name
		var parameters: [String : AnyObject] = [:]
		if let limit = limit {
			 parameters["limit"] = limit
		}
		if let before = before {
			parameters["before"] = before
		}
		return self.backend.future(path: path, method: .GET, parameters: parameters)
			.andThen { DataParser().dictionaries(from: $0.0) }
			.andThen { EntityParser().entities(from: $0) }
	}
	
	func getNMessagesWithUser(_ withJID: String, limit: NSNumber?, before: NSNumber?) -> Future<[EntityType], JaymeError> {
		let path = self.name + "/" + withJID
		var parameters: [String : AnyObject]? = nil
		if let limit = limit {
			parameters!["limit"] = limit.intValue as AnyObject?
		}
		if let before = before {
			parameters!["before"] = before.int64Value as AnyObject?
		}
		return self.backend.future(path: path, method: .GET, parameters: parameters)
			.andThen { DataParser().dictionaries(from: $0.0) }
			.andThen { EntityParser().entities(from: $0) }
	}
	
}
