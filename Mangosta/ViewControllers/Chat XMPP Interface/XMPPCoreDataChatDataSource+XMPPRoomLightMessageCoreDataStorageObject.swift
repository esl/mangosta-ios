//
//  XMPPCoreDataChatDataSource+XMPPRoomLightMessageCoreDataStorageObject.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 23/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

extension XMPPCoreDataChatDataSource {
    
    convenience init(roomStorageManagedObjectContext: NSManagedObjectContext, roomJid: XMPPJID, roster: XMPPRoster, retransmission: XMPPRetransmission) {
        let request = NSFetchRequest<XMPPRoomLightMessageCoreDataStorageObject>(entityName: "XMPPRoomLightMessageCoreDataStorageObject")
        request.predicate = NSPredicate(format: "roomJIDStr = %@", roomJid.bare() as NSString)
        request.sortDescriptors = [NSSortDescriptor(key: "localTimestamp", ascending: true)]
        let roomStorageResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: roomStorageManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.init(fetchedResultsController: roomStorageResultsController, roster: roster, retransmission: retransmission)
    }
}

extension XMPPRoomLightMessageCoreDataStorageObject: TextMessageFetchRequestResult {
    
    var source: XMPPMessage { return message }
    var senderId: String { return nickname ?? roomJIDStr }
    var isIncoming: Bool { return !isFromMe }
    var date: Date { return localTimestamp }
    var text: String { return body }
}
