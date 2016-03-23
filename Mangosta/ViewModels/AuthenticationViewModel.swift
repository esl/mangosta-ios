//
//  AuthenticationViewModel.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

class AuthenticationViewModel {
	let userJidString: String
	let password: String
	
	init(authentication: AuthenticationModel) {
		self.userJidString = authentication.jid.bare()
		self.password = authentication.password
	}
}