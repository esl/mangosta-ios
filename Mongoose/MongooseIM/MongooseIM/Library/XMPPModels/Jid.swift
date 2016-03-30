//
//  Jid.swift
//  MongooseIM
//
//  Created by Tom Ryan on 2/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

public struct Jid {
	public let user: String?
	public let domain: String
	public let resource: String?
	
	public init(jid: XMPPJID) {
		user = jid.user
		domain = jid.domain
		resource = jid.resource
	}
	
	public init(user: String?, domain: String, resource: String?) {
		self.user = user
		self.domain = domain
		self.resource = resource
	}
}