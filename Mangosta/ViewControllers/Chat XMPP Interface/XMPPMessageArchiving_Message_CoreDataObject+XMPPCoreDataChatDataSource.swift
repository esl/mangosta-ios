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
    var senderId: String { return isOutgoing ? streamBareJidStr : bareJidStr }
    var isIncoming: Bool { return !isOutgoing }
    var date: Date { return timestamp }
    
    // TODO: with the current architecture it is not possible to obtain sender resource information for locally sent messages
    /*
     For such messages an assumption is made that all have been sent with the same, "null" resource. As a result, there may be some edge cases:
     - where an outgoing message appears corrected for the sender but not for the recipient (e.g. because the client's actual resource changed)
     - where an outgoing message appears non-editable for the sender (e.g. because it was downloaded via MAM and has a full sender JID assigned)
     */

    func isChatOriginContinuityMaintained(with other: MessageFetchRequestResult) -> Bool {
        return senderId != other.senderId || source.fromStr() as String? == other.source.fromStr() as String?
    }
    
    func isChatOriginContinuityMaintained(inStreamWithLocalJid streamLocalJid: XMPPJID) -> Bool {
        return senderId == streamLocalJid.bare() && (source.fromStr() == nil || source.fromStr() == streamLocalJid.full())
    }
}
