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
	public let jid: XMPPJID
	public let password: String
	public var serverName: String?
	
	public func save() {
		var dict = [String:String]()
		dict["jid"] = self.jid.bare()
		dict["password"] = self.password
		if let server = self.serverName {
			dict["serverName"] = server
		}
		
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
	
	public init(jidString: String, serverName: String, password: String) {
		self.jid = XMPPJID.jidWithString(jidString)
		self.serverName = serverName
		self.password = password
	}
	
	static public func load() -> AuthenticationModel? {
		if let authDict = NSUserDefaults.standardUserDefaults().objectForKey(Constants.Preferences.Authentication) as? [String:String] {
			let authJidString = "kentron2@jabb.im" //authDict["jid"]!
			let pass = "1234" //authDict["password"]!
			
			if let server = authDict["serverName"] {
				return AuthenticationModel(jidString: authJidString, serverName: "jabb.im", password: pass)
			}
			
			return AuthenticationModel(jid: XMPPJID.jidWithString(authJidString), password: pass)
		}
		return nil
	}
	
	static public func remove() {
		NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.Preferences.Authentication)
		NSUserDefaults.standardUserDefaults().synchronize()
	}
}

