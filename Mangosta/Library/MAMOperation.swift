//
//  MAMOperation.swift
//  Mangosta
//
//  Created by Andres Canal on 5/12/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class MAMOperation: AsyncOperation, XMPPMessageArchiveManagementDelegate {
	var mainOperation: (() -> ())?
	var boolCompletion: ((result: Bool) -> ())?
	var stream: XMPPStream?

	var messageArchiveManagement: XMPPMessageArchiveManagement?

	override func execute() {
		self.messageArchiveManagement = XMPPMessageArchiveManagement()
		self.messageArchiveManagement!.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.messageArchiveManagement!.activate(self.stream)
		self.mainOperation?()
	}
	
	class func retrieveHistory(stream: XMPPStream, jid: XMPPJID, completion: (result: Bool) -> ()) -> MAMOperation {
		let mamOperation = MAMOperation()
		mamOperation.stream = stream
		
		mamOperation.mainOperation = {
			mamOperation.messageArchiveManagement!.retrieveMessageArchiveFrom(jid, withPageSize: 20)
		}

		mamOperation.boolCompletion = completion
		return mamOperation
	}

	private func finishAndRemoveDelegates() {
		self.messageArchiveManagement!.removeDelegate(self)
		self.messageArchiveManagement!.deactivate()
		finish()
	}

	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessagesWithSet resultSet: XMPPResultSet!) {
		self.boolCompletion?(result: true)
		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveError error: DDXMLElement!) {
		self.boolCompletion?(result: false)
		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMAMMessage message: XMPPMessage!) {
		let outgoing = message.from().bare() == self.stream!.myJID.bare()
//		self.messageArchiving.xmppMessageArchivingStorage.archiveMessage(message, outgoing: outgoing, xmppStream: self.stream!)
	}
}
