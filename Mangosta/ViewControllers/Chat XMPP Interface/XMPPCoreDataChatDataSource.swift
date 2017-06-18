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

    private(set) var chatItems = [ChatItemProtocol]()
    weak var delegate: ChatDataSourceDelegateProtocol?
    
    private let textMessageFetchRequestResultProvider: TextMessageFetchRequestResultProvider
    private let messageContentFilters: [XMPPCoreDataChatDataSourceMessageContentFiltering]
    
    convenience init(messageArchivingManagedObjectContext: NSManagedObjectContext, userJid: XMPPJID, messageContentFilters: [XMPPCoreDataChatDataSourceMessageContentFiltering]) {
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        request.predicate = NSPredicate(format: "bareJidStr = %@", userJid.bare() as NSString)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let messageArchivingResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: messageArchivingManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.init(fetchedResultsController: messageArchivingResultsController, messageContentFilters: messageContentFilters)
    }
    
    convenience init(roomStorageManagedObjectContext: NSManagedObjectContext, roomJid: XMPPJID, messageContentFilters: [XMPPCoreDataChatDataSourceMessageContentFiltering]) {
        let request = NSFetchRequest<XMPPRoomLightMessageCoreDataStorageObject>(entityName: "XMPPRoomLightMessageCoreDataStorageObject")
        request.predicate = NSPredicate(format: "roomJIDStr = %@", roomJid.bare() as NSString)
        request.sortDescriptors = [NSSortDescriptor(key: "localTimestamp", ascending: true)]
        let roomStorageResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: roomStorageManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.init(fetchedResultsController: roomStorageResultsController, messageContentFilters: messageContentFilters)
    }
        
    private init<MessageResultType: TextMessageFetchRequestResult>(fetchedResultsController: NSFetchedResultsController<MessageResultType>, messageContentFilters: [XMPPCoreDataChatDataSourceMessageContentFiltering]) {
        textMessageFetchRequestResultProvider = _TextMessageFetchRequestResultProvider(base: fetchedResultsController)
        self.messageContentFilters = messageContentFilters
     
        super.init()
        
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()
        updateChatItems()
    }
    
    fileprivate func updateChatItems() {
        chatItems = textMessageFetchRequestResultProvider.fetchedObjects!.map { messageResultItem in
            let baseModel = MessageModel(
                uid: messageResultItem.uid,
                senderId: messageResultItem.senderId,
                type: MessageModel.textItemType,
                isIncoming: messageResultItem.isIncoming,
                date: messageResultItem.date,
                status: .success
            )
            
            let filteredText = messageContentFilters.reduce(messageResultItem.text) { filteredText, filter in
                filter.xmppCoreDataChatDataSource(self, willCreateMessageModelWithTextContent: filteredText, for: messageResultItem.source)
            }
            
            return TextMessageModel(messageModel: baseModel, text: filteredText)
        }
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
        updateChatItems()
        delegate?.chatDataSourceDidUpdate(self, updateType: .normal)
    }
}

protocol XMPPCoreDataChatDataSourceMessageContentFiltering {
    
    func xmppCoreDataChatDataSource(_ dataSource: XMPPCoreDataChatDataSource, willCreateMessageModelWithTextContent textContent: String, for message: XMPPMessage) -> String
}

private protocol BaseMessageFetchRequestResult: NSFetchRequestResult {
    
    var source: XMPPMessage { get }
    var uid: String { get }
    var senderId: String { get }
    var isIncoming: Bool { get }
    var date: Date { get }
}

private protocol TextMessageFetchRequestResult: BaseMessageFetchRequestResult {
    
    var text: String { get }
}

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

extension BaseMessageFetchRequestResult where Self: NSManagedObject {
    
    var uid: String { return objectID.uriRepresentation().absoluteString }
}

extension XMPPMessageArchiving_Message_CoreDataObject: TextMessageFetchRequestResult {
    
    var source: XMPPMessage { return message }
    var senderId: String { return bareJidStr }
    var isIncoming: Bool { return !isOutgoing }
    var date: Date { return timestamp }
    var text: String { return body }
}

extension XMPPRoomLightMessageCoreDataStorageObject: TextMessageFetchRequestResult {
    
    var source: XMPPMessage { return message }
    var senderId: String { return nickname ?? roomJIDStr }
    var isIncoming: Bool { return !isFromMe }
    var date: Date { return localTimestamp }
    var text: String { return body }
}
