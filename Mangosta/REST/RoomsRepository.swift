//
//  RoomsRepository.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import Jayme

class RoomRepository: CRUDRepository {
	
	typealias EntityType = Room
	let backend = URLSessionBackend.MongooseREST()
	let name = "rooms"
	
	// To create a room use create
	
	// To return room's details use findByID
	
	
	func addUserToRoom(_ entity: EntityType, userJID : String) -> Future<EntityType, JaymeError> {
		let path = self.name + "/" + entity.id + "/users"
		let parameter : [String: AnyObject]? = ["name":userJID as AnyObject]
		return self.backend.future(path: path, method: .POST, parameters: parameter)
			.andThen { DataParser().dictionary(from: $0.0) }
			.andThen { EntityParser().entity(from: $0) }
	}
	
	// Removes a user from the room
	
	func deleteUserFromRoom(_ entity: EntityType, userJID : String) -> Future<Void, JaymeError> {
		let path = self.name + "/" + entity.id + "/" + userJID
		return self.backend.future(path: path, method: .DELETE, parameters: nil)
			.map { _ in return }
	}
	
	func getMessagesFromRoom(_ id: EntityType.IdentifierType, limit: NSNumber?, before: NSNumber?) -> Future<[Message], JaymeError> {
		let path = self.name + "/" + id + "/messages"
		var parameters : [String : AnyObject]? = nil
		if let limit = limit {
			parameters!["limit"] = limit.intValue as AnyObject?
		}
		if let before = before {
			parameters!["before"] = before.intValue as AnyObject?
		}
		return self.backend.future(path: path, method: .GET, parameters: parameters)
			.andThen { DataParser().dictionaries(from: $0.0) }
			.andThen { EntityParser().entities(from: $0) }
	}
	
	func sendMessageToRoom(_ entity: EntityType, messageBody: String) -> Future<EntityType, JaymeError> {
		let path = self.name + "/" + entity.id + "/messages"
		let parameter : [String : AnyObject]? = ["body":messageBody as AnyObject]
        return self.backend.future(path: path, method: .POST, parameters: parameter)
			.andThen { DataParser().dictionary(from: $0.0) }
			.andThen { EntityParser().entity(from: $0) }
	}
}
