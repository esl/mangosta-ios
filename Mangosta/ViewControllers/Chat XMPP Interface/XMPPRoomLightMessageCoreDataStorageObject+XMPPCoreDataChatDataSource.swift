//
//  XMPPRoomLightMessageCoreDataStorageObject+XMPPCoreDataChatDataSource.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

extension XMPPRoomLightMessageCoreDataStorageObject {
    
    static func chatDataSourceFetchedResultsController(with managedObjectContext: NSManagedObjectContext, roomJid: XMPPJID) -> NSFetchedResultsController<XMPPRoomLightMessageCoreDataStorageObject> {
        let request = NSFetchRequest<XMPPRoomLightMessageCoreDataStorageObject>(entityName: "XMPPRoomLightMessageCoreDataStorageObject")
        request.predicate = NSPredicate(format: "roomJIDStr = %@", roomJid.bare() as NSString)
        request.sortDescriptors = [NSSortDescriptor(key: "localTimestamp", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
}

extension XMPPRoomLightMessageCoreDataStorageObject: MessageFetchRequestResult {
    
    var source: XMPPMessage { return message }
    var senderId: String { return nickname ?? roomJIDStr }
    var isIncoming: Bool { return !isFromMe }
    var date: Date { return localTimestamp }
    
    func isChatOriginContinuityMaintained(with other: MessageFetchRequestResult) -> Bool {
        guard senderId != other.senderId else {
            return true
        }
        
        guard let affiliationsElement = other.source.forName("x", xmlns: "urn:xmpp:muclight:0#affiliations") else {
            return true
        }
        
        return !affiliationsElement.elements(forName: "user").contains { userElement in
            ["member", "owner"].contains(userElement.attributeStringValue(forName: "affiliation")!) && userElement.stringValue == senderId
        }
    }
    
    func isChatOriginContinuityMaintained(inStreamWithLocalJid streamLocalJid: XMPPJID) -> Bool {
        return senderId == streamLocalJid.bare()
    }
}
