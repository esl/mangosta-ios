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
	var completionFields: ((result: Bool, fields: [(String, String)]) -> ())?

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
		let fields = [XMPPMessageArchiveManagement.fieldWithVar("with", type: nil, andValue: jid.bare())]
		mamOperation.mainOperation = {
			mamOperation.messageArchiveManagement!.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
		}

		mamOperation.completion = completion
		return mamOperation
	}
	
	class func retrieveForms(stream: XMPPStream, completion: (result: Bool, fields: [(String, String)]) -> ()) -> MAMOperation {
		let mamOperation = MAMOperation()
		mamOperation.stream = stream

		mamOperation.mainOperation = {
			mamOperation.messageArchiveManagement!.retrieveFormFields()
		}

		mamOperation.completionFields = completion
		return mamOperation
	}

	private func finishAndRemoveDelegates() {
		self.messageArchiveManagement!.removeDelegate(self)
		self.messageArchiveManagement!.deactivate()
		finish()
	}

	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFailToReceiveFormFields iq: XMPPIQ!) {
		self.completion?(result: false, lastID: nil)
		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveFormFields iq: XMPPIQ!) {
		let fields = iq.elementForName("x").elementsForName("field").map { (field) -> (String, String) in
			let f = field as! NSXMLElement
			return (f.attributeForName("var").stringValue()!, f.attributeForName("type").stringValue()!)
		}
		self.completionFields!(result: true, fields: fields)

		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessagesWithSet resultSet: XMPPResultSet!) {
		self.completion?(result: true, lastID: resultSet.last())
		self.finishAndRemoveDelegates()
	}
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFailToReceiveMessages error: XMPPIQ!) {
		self.completion?(result: false, lastID: nil)
		self.finishAndRemoveDelegates()
	}

	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMAMMessage message: XMPPMessage!) {

	}
}
