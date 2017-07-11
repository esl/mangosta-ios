//
//  XMPPMessageArchiving_Message_CoreDataObject+XMPPCoreDataChatDataSource.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

extension XMPPMessageArchiving_Message_CoreDataObject {
    
    static func chatDataSourceFetchedResultsController(with managedObjectContext: NSManagedObjectContext, userJid: XMPPJID) -> NSFetchedResultsController<XMPPMessageArchiving_Message_CoreDataObject> {
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        request.predicate = NSPredicate(format: "bareJidStr = %@", userJid.bare() as NSString)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
}

extension XMPPMessageArchiving_Message_CoreDataObject: MessageFetchRequestResult {
    
    var source: XMPPMessage { return message }
    var senderId: String { return bareJidStr }
    var isIncoming: Bool { return !isOutgoing }
    var date: Date { return timestamp }
}
