//
//  XMPPCoreDataChatBaseMessageModelProvider.swift
//  Mangosta
//
//  Created by Piotrek on 02/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import ChattoAdditions
import XMPPFramework

class XMPPCoreDataChatBaseMessageModelProvider: NSObject, XMPPCoreDataChatDataSourceItemEventSource {
    
    private let xmppRetransmission: XMPPRetransmission
    
    init(xmppRetransmission: XMPPRetransmission) {
        self.xmppRetransmission = xmppRetransmission
    }
    
    func messageModel(ofType messageType: String, for messageFetchRequestResult: MessageFetchRequestResult) -> MessageModel {
        let isUnconfirmed = messageFetchRequestResult.source.elementID() != nil && xmppRetransmission.storage.containsMonitoredMessage(withId: messageFetchRequestResult.source.elementID())
        let isTransmitted = isUnconfirmed && xmppRetransmission.xmppStream.isAuthenticated()
        
        return MessageModel(
            uid: "\(messageFetchRequestResult.uid)/\(messageType)",
            senderId: messageFetchRequestResult.senderId,
            type: messageType,
            isIncoming: messageFetchRequestResult.isIncoming,
            date: messageFetchRequestResult.date,
            status: isTransmitted ? .sending : isUnconfirmed ? .failed : .success
        )
    }
    
    func startObservingChatItemEvents(with sink: XMPPCoreDataChatDataSource.ItemEventSink) {
        xmppRetransmission.xmppStream.addDelegate(sink, delegateQueue: .main)
        xmppRetransmission.addDelegate(sink, delegateQueue: .main)
    }
}

extension XMPPCoreDataChatDataSource.ItemEventSink: XMPPStreamDelegate {
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        invalidateCurrentChatItems()
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
        invalidateCurrentChatItems()
    }
}

extension XMPPCoreDataChatDataSource.ItemEventSink: XMPPRetransmissionDelegate {
    
    func xmppRetransmission(_ xmppRetransmission: XMPPRetransmission!, didConfirmTransmissionFor elements: [XMPPElement]!) {
        invalidateCurrentChatItems()
    }
    
    func xmppRetransmission(_ xmppRetransmission: XMPPRetransmission!, didBeginMonitoringTransmissionFor element: XMPPElement!) {
        invalidateCurrentChatItems()
    }
}

private extension XMPPRetransmissionStorage {
    
    func containsMonitoredMessage(withId messageId: String) -> Bool {
        var containsMonitoredMessage = false
        enumerateMonitoredElements { (_, element, _) in
            guard let message = element as? XMPPMessage, message.elementID() == Optional(messageId) else {
                return
            }
            containsMonitoredMessage = true
        }
        return containsMonitoredMessage
    }
}
