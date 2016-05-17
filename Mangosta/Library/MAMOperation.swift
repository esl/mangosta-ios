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
	var completion: ((result: Bool, lastID: String?) -> ())?
	var stream: XMPPStream?

	var messageArchiveManagement: XMPPMessageArchiveManagement?

	override func execute() {
		self.messageArchiveManagement = XMPPMessageArchiveManagement()
		self.messageArchiveManagement!.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.messageArchiveManagement!.activate(self.stream)
		self.mainOperation?()
	}
	
	class func retrieveHistory(stream: XMPPStream, jid: XMPPJID, pageSize: Int, lastID: String? , completion: (result: Bool, lastID: String?) -> ()) -> MAMOperation {
		let mamOperation = MAMOperation()
		mamOperation.stream = stream

		let resultSet = XMPPResultSet(max: pageSize, after: lastID)
		mamOperation.mainOperation = {
			mamOperation.messageArchiveManagement!.retrieveMessageArchiveFrom(jid, withResultSet: resultSet)
		}

		mamOperation.completion = completion
		return mamOperation
	}

	private func finishAndRemoveDelegates() {
		self.messageArchiveManagement!.removeDelegate(self)
		self.messageArchiveManagement!.deactivate()
		finish()
	}

	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessagesWithSet resultSet: XMPPResultSet!) {
		self.completion?(result: true, lastID: resultSet.last())
		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveError error: DDXMLElement!) {
		self.completion?(result: false, lastID: nil)
		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMAMMessage message: XMPPMessage!) {

	}
}
