//
//  MensajesRepository.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//


class MessageRepository: CRUDRepository {
	
	typealias EntityType = Message
	let backend = NSURLSessionBackend.MongooseREST()
	let name = "messages"
}