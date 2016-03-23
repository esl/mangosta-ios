//
//  StreamOperation.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/15/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

enum StreamStatus {
	case Ready, Connected, Authenticated, Failed
}

class StreamOperation: AsyncOperation, XMPPStreamDelegate {
	var completion: ((stream: XMPPStream?) -> ())?
	var stream: XMPPStream
	var status = StreamStatus.Ready
	var password: String
	var hostName: String
	var userJID: XMPPJID
	
	private init(hostName: String, userJID: XMPPJID, password: String) {
		//self.rosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
		self.hostName = hostName
		self.password = password
		self.userJID = userJID
		
		self.stream = XMPPStream()
		self.stream.startTLSPolicy = XMPPStreamStartTLSPolicy.Allowed
		self.stream.hostName = hostName
		self.stream.myJID = userJID
		
		self.status = StreamStatus.Ready
		
		super.init()
		
		self.stream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
	}
	
	private init(stream: XMPPStream, password: String) {
		//self.rosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
		
		self.status = StreamStatus.Connected
		self.password = password
		self.stream = stream
		self.userJID = stream.myJID
		self.hostName = stream.hostName
		
		super.init()
		
		self.stream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
	}
	
	class func createAndConnectStream(hostName: String, userJID: XMPPJID, password: String, completion: (stream: XMPPStream?) -> Void) -> StreamOperation {
		let streamOperation = StreamOperation(hostName: hostName, userJID: userJID, password: password)
		streamOperation.completion = completion
		return streamOperation
	}
	
	class func authenticateStream(stream: XMPPStream, password: String, completion: (stream: XMPPStream?) -> Void) -> StreamOperation {
		let streamOperation = StreamOperation(stream: stream, password: password)
		streamOperation.completion = completion
		return streamOperation
	}
	
	override func execute() {
		switch self.status {
		case .Ready:
			self.connect()
		case .Connected:
			self.authenticate()
		case .Authenticated:
			if let success = self.completion {
				success(stream: self.stream)
			}
			self.finish()
		default:()
		}
	}
	
	private func connect() {
		var error : NSError?
		do {
			try self.stream.connectWithTimeout(XMPPStreamTimeoutNone)
		} catch let error1 as NSError {
			error = error1
		}
		
		if error != nil {
			status = .Failed
		}
	}
	
	private func authenticate() {
		var error: NSError?
		do {
			try self.stream.authenticateWithPassword(self.password)
		} catch let error1 as NSError {
			error = error1
		}
		
		if error != nil {
			status = .Failed
		}
	}
	
	// MARK: Connection delegates
	func xmppStreamDidConnect(sender: XMPPStream!) {
		status = .Connected
		
		self.execute()
	}
	
	func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
		status = .Failed
		self.finish()
		
		if let success = self.completion {
			success(stream: nil)
		}
	}
	
	// MARK: Authentication delegates
	func xmppStreamDidAuthenticate(sender: XMPPStream!) {
		status = .Authenticated
		
		self.execute()
	}
	
	func xmppStream(sender: XMPPStream!, didReceiveMessage message: XMPPMessage!) {
		print(message)
	}
	
	func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
		print(presence)
	}
	
	func xmppStream(sender: XMPPStream!, didReceiveIQ iq: XMPPIQ!) -> Bool {
		print(iq)
		return true
	}
	
	func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
		status = .Failed
		self.finish()
		
		if let success = self.completion {
			success(stream: nil)
		}
	}
	
	func xmppStream(sender: XMPPStream!, willSecureWithSettings settings: NSMutableDictionary!) {
		settings.setObject(sender.myJID.domain, forKey: kCFStreamSSLPeerName as String)
	}
	
	func xmppStream(sender: XMPPStream!, didReceiveTrust trust: SecTrust!, completionHandler: ((Bool) -> Void)!) {
		let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
		dispatch_async(bgQueue, {
			//var result = kSecTrustResultDeny
			var result = SecTrustResultType(kSecTrustResultDeny)
			let status = SecTrustEvaluate(trust, &result)
			
			let success = result == SecTrustResultType(kSecTrustResultProceed) || result == SecTrustResultType(kSecTrustResultUnspecified)
			
			if status == noErr && success {
				completionHandler(true)
			} else {
				completionHandler(false)
			}
		})
	}
	
	private func errorWithDescription(description: String) -> NSError{
		return NSError(domain: "StreamOperation", code: 100, userInfo: [NSLocalizedDescriptionKey : description])
	}
}

