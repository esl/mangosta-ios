//
//  XMPPCoreDataChatDataSource.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 29/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Chatto
import ChattoAdditions
import XMPPFramework

class XMPPCoreDataChatDataSource : NSObject {

    private class TextMessageFetchRequestResultProvider {
        
        var fetchedObjects: [TextMessageFetchRequestResult]? { fatalError("Abstract property") }
    }
    
    private class _TextMessageFetchRequestResultProvider<ResultType: TextMessageFetchRequestResult>: TextMessageFetchRequestResultProvider {
        
        let base: NSFetchedResultsController<ResultType>
        override var fetchedObjects: [TextMessageFetchRequestResult]? { return base.fetchedObjects }
        
        init(base: NSFetchedResultsController<ResultType>) {
            self.base = base
        }
    }
    
    private(set) var chatItems = [ChatItemProtocol]()
    weak var delegate: ChatDataSourceDelegateProtocol?
    
    private let textMessageFetchRequestResultProvider: TextMessageFetchRequestResultProvider
    private let roster: XMPPRoster
    private let retransmission: XMPPRetransmission
    
    init<MessageResultType: TextMessageFetchRequestResult>(fetchedResultsController: NSFetchedResultsController<MessageResultType>, roster: XMPPRoster, retransmission: XMPPRetransmission) {
        textMessageFetchRequestResultProvider = _TextMessageFetchRequestResultProvider(base: fetchedResultsController)
        self.roster = roster
        self.retransmission = retransmission
        
        super.init()
        
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()
        
        retransmission.xmppStream.addDelegate(self, delegateQueue: .main)
        retransmission.addDelegate(self, delegateQueue: .main)
        
        updateChatItems(with: UpdateType.firstLoad)
    }
    
    fileprivate func updateChatItems(with updateType: UpdateType) {
        let unconfirmedMessageIds = retransmission.storage.processedMessageIds()
        
        chatItems = textMessageFetchRequestResultProvider.fetchedObjects!.map { messageResultItem in
            let isUnconfirmed = messageResultItem.source.elementID() != nil && unconfirmedMessageIds.contains(messageResultItem.source.elementID())
            let isTransmitted = isUnconfirmed && retransmission.xmppStream.isAuthenticated()
            
            let baseModel = MessageModel(
                uid: messageResultItem.uid,
                senderId: messageResultItem.senderId,
                type: MessageModel.textItemType,
                isIncoming: messageResultItem.isIncoming,
                date: messageResultItem.date,
                status: isTransmitted ? .sending : isUnconfirmed ? .failed : .success
            )
            let text = roster.transformedTextContent(for: messageResultItem.source, withTextContent: messageResultItem.text)
            
            return TextMessageModel(messageModel: baseModel, text: text)
        }
        
        delegate?.chatDataSourceDidUpdate(self, updateType: updateType)
    }
}

extension XMPPCoreDataChatDataSource: ChatDataSourceProtocol {
    
    // TODO: consider paging with MAM
    
    var hasMoreNext: Bool { return false }
    var hasMorePrevious: Bool { return false }
    
    func loadNext() {}
    func loadPrevious() {}
    func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion:(_ didAdjust: Bool) -> Void) { completion(false) }
}

extension XMPPCoreDataChatDataSource: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateChatItems(with: UpdateType.normal)
    }
}

extension XMPPCoreDataChatDataSource: XMPPStreamDelegate {
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        updateChatItems(with: UpdateType.normal)
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
        updateChatItems(with: UpdateType.normal)
    }
}

extension XMPPCoreDataChatDataSource: XMPPRetransmissionDelegate {
    
    func xmppRetransmission(_ xmppRetransmission: XMPPRetransmission!, didConfirmTransmissionFor elements: [XMPPElement]!) {
        updateChatItems(with: UpdateType.normal)
    }
    
    func xmppRetransmission(_ xmppRetransmission: XMPPRetransmission!, didBeginMonitoringTransmissionFor element: XMPPElement!) {
        updateChatItems(with: UpdateType.normal)
    }
}

protocol BaseMessageFetchRequestResult: NSFetchRequestResult {
    
    var source: XMPPMessage { get }
    var uid: String { get }
    var senderId: String { get }
    var isIncoming: Bool { get }
    var date: Date { get }
}

extension BaseMessageFetchRequestResult where Self: NSManagedObject {
    
    var uid: String { return objectID.uriRepresentation().absoluteString }
}

protocol TextMessageFetchRequestResult: BaseMessageFetchRequestResult {
    
    var text: String { get }
}

private extension XMPPRoster {
    
    func transformedTextContent(for message: XMPPMessage, withTextContent textContent: String) -> String {
        // TODO: should have a designated chat item type for "me" commands
        if (textContent as NSString).hasXMPPMeCommandPrefix(), let substitution = meCommandSubstitution(for: message) {
            return "\(substitution) \((textContent as NSString).xmppMessageBodyStringByTrimmingMeCommand()!)"
        } else {
            return textContent
        }
    }
}

private extension XMPPRetransmissionStorage {
    
    func processedMessageIds() -> Set<String> {
        var processedMessageIds = Set<String>()
        enumerateMonitoredElements { (_, element, _) in
            guard let message = element as? XMPPMessage, let messageId = message.elementID() else {
                return
            }
            processedMessageIds.insert(messageId)
        }
        return processedMessageIds
    }
}
