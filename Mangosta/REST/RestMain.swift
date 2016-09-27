//
//  RestMain.swift
//  Mangosta
//
//  Created by Sergio E. Abraham on 9/26/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation


class RestMain {
	func sendMessage(jidString: String) {
		
	}
	
	func getRooms() -> [Room] {
		RoomRepository().findAll().start() { result in
			switch result {
			case .Success(let users): break
			// You've got all your users fetched in this array!
			case .Failure(let error): break
				// You've got a discrete JaymeError indicating what happened
			}
		}
		return []
	}
	
}