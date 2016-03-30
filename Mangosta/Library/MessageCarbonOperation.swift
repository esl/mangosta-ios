//
//  MessageCarbonOperation.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/18/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public class MessageCarbonOperation: AsyncOperation, XMPPMessageCarbonsDelegate, XMPPStreamDelegate {
	var stream: XMPPStream
	public var completion: BoolCompletion?
	var carbon: XMPPMessageCarbons
	
	private init(stream: XMPPStream) {
		self.stream = stream
		self.carbon = XMPPMessageCarbons()
	}
	
	public class func toggleCarbons(enabled: Bool, stream: XMPPStream, completion: BoolCompletion) -> MessageCarbonOperation {
		let operation = MessageCarbonOperation(stream: stream)
		if enabled {
			operation.carbon.enableMessageCarbons()
		} else {
			operation.carbon.disableMessageCarbons()
		}
		operation.completion = completion

		return operation
	}

	private func sendCarbonRequest() {
		
	}
	
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, didReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
	
	public func xmppMessageCarbons(xmppMessageCarbons: XMPPMessageCarbons!, willReceiveMessage message: XMPPMessage!, outgoing isOutgoing: Bool) {
		//
	}
	
//- (void)enableMessageCarbonsIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)trackerInfo
}

