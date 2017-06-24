//
//  XMPPCoreDataChatDataSource+XMPPMessageArchiving_Message_CoreDataObject.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

extension XMPPCoreDataChatDataSource {
    
    convenience init(messageArchivingManagedObjectContext: NSManagedObjectContext, userJid: XMPPJID, roster: XMPPRoster, retransmission: XMPPRetransmission) {
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        request.predicate = NSPredicate(format: "bareJidStr = %@", userJid.bare() as NSString)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let messageArchivingResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: messageArchivingManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.init(fetchedResultsController: messageArchivingResultsController, roster: roster, retransmission: retransmission)
    }
}

extension XMPPMessageArchiving_Message_CoreDataObject: TextMessageFetchRequestResult {
    
    var source: XMPPMessage { return message }
    var senderId: String { return bareJidStr }
    var isIncoming: Bool { return !isOutgoing }
    var date: Date { return timestamp }
    var text: String { return body }
}
