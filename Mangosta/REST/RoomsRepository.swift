//
//  RoomsRepository.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

class RoomRepository: CRUDRepository {

	typealias EntityType = Room
	let backend = NSURLSessionBackend.MongooseREST()
	let name = "rooms"
}
