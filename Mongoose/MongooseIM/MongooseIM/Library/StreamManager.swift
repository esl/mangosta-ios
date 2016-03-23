//
//  StreamManager.swift
//  MongooseIM
//
//  Created by Tom Ryan on 2/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

public class StreamManager : XMPPStreamDelegate {
	public static let manager = StreamManager()
	internal let reconnect : XMPPReconnect
	
	private var stream : XMPPStream?
	public var authenticationModel: AuthenticationModel?
	
	private init() {
		self.reconnect = XMPPReconnect()
		self.reconnect.autoReconnect = true
	}
	
	public func connect() -> Future<XMPPStream, NSError> {
		return Future() { completion in
			if let authModel = self.authenticationModel {
				
			}
		}
	}
}