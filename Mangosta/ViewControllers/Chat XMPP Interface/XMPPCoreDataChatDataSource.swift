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

    enum ItemPosition {
        
        case attachedTo(messageFetchRequestResultIndex: Int)
        case tail
    }

    class ItemEventSink: NSObject {
        
        private unowned let dataSource: XMPPCoreDataChatDataSource
        
        fileprivate init(dataSource: XMPPCoreDataChatDataSource) {
            self.dataSource = dataSource
        }
        
        func invalidateCurrentChatItems() {
            dataSource.updateChatItems(with: UpdateType.normal)
        }
    }
    
    private class MessageFetchRequestResultProvider {
        
        var fetchedObjects: [MessageFetchRequestResult]? { fatalError("Abstract property") }
    }
    
    private class _MessageFetchRequestResultProvider<ResultType: MessageFetchRequestResult>: MessageFetchRequestResultProvider {
        
        let base: NSFetchedResultsController<ResultType>
        override var fetchedObjects: [MessageFetchRequestResult]? { return base.fetchedObjects }
        
        init(base: NSFetchedResultsController<ResultType>) {
            self.base = base
        }
    }
    
    private(set) var chatItems = [ChatItemProtocol]()
    weak var delegate: ChatDataSourceDelegateProtocol?
    
    private let messageFetchRequestResultProvider: MessageFetchRequestResultProvider
    private let chatItemBuilders: [XMPPCoreDataChatDataSourceItemBuilder]
    private var chatItemEventSink: ItemEventSink!
    
    init<MessageResultType: MessageFetchRequestResult>(fetchedResultsController: NSFetchedResultsController<MessageResultType>, chatItemBuilders: [XMPPCoreDataChatDataSourceItemBuilder], chatItemEventSources: [XMPPCoreDataChatDataSourceItemEventSource]) {
        messageFetchRequestResultProvider = _MessageFetchRequestResultProvider(base: fetchedResultsController)
        self.chatItemBuilders = chatItemBuilders
        
        super.init()
        
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()
        
        chatItemEventSink = ItemEventSink(dataSource: self)
        for eventSource in chatItemEventSources {
            eventSource.startObservingChatItemEvents(with: chatItemEventSink)
        }
        
        updateChatItems(with: UpdateType.firstLoad)
    }
    
    fileprivate func updateChatItems(with updateType: UpdateType) {
        let messageFetchRequestResults = messageFetchRequestResultProvider.fetchedObjects!
        let positions = messageFetchRequestResults.indices.map { ItemPosition.attachedTo(messageFetchRequestResultIndex: $0) } + [.tail]
        
        chatItems = positions.flatMap { position in
            chatItemBuilders.flatMap { builder in
                builder.chatItems(at: position, in: messageFetchRequestResults)
            }
        }
        
        delegate?.chatDataSourceDidUpdate(self, updateType: updateType)
    }
}

protocol XMPPCoreDataChatDataSourceItemBuilder {
    
    func chatItems(at position: XMPPCoreDataChatDataSource.ItemPosition, in messageFetchRequestResults: [MessageFetchRequestResult]) -> [ChatItemProtocol]
}

protocol XMPPCoreDataChatDataSourceItemEventSource {
    
    func startObservingChatItemEvents(with sink: XMPPCoreDataChatDataSource.ItemEventSink)
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


protocol MessageFetchRequestResult: NSFetchRequestResult {
    
    var source: XMPPMessage { get }
    var uid: String { get }
    var senderId: String { get }
    var isIncoming: Bool { get }
    var date: Date { get }
}

extension MessageFetchRequestResult where Self: NSManagedObject {
    
    var uid: String { return objectID.uriRepresentation().absoluteString }
}
