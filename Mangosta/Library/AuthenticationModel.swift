//
//  AuthenticationModel.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/14/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public struct AuthenticationModel {
	public let jid : XMPPJID
	public let password : String
	
	public func save() {
		var dict = [String:String]()
		dict["jid"] = self.jid.bare()
		dict["password"] = self.password
		
		NSUserDefaults.standardUserDefaults().setObject(dict, forKey: Constants.Preferences.Authentication)
		NSUserDefaults.standardUserDefaults().synchronize()
	}
	
	public init(jidString: String, password: String) {
		let myJid = XMPPJID.jidWithString(jidString)
		self.jid = myJid
		self.password = password
	}
	
	public init(jid: XMPPJID, password: String) {
		self.jid = jid
		self.password = password
	}
	
	static public func load() -> AuthenticationModel? {
		if let authDict = NSUserDefaults.standardUserDefaults().objectForKey(Constants.Preferences.Authentication) as? [String:String] {
			let authJid = XMPPJID.jidWithString(authDict["jid"])
			let pass = authDict["password"]!
			
			let auth = AuthenticationModel(jid: authJid, password: pass)
			
			return auth
		}
		return nil
	}
	
	static public func remove() {
		NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.Preferences.Authentication)
		
		NSUserDefaults.standardUserDefaults().synchronize()
	}
}