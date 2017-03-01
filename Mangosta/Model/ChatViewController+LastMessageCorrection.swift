//
//  ChatViewController+fetchMessages.swift
//  Mangosta
//
//  Created by Sergio Abraham on 2/24/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

// MARK: Last Message Correction & MAM
extension ChatViewController {
    func replaceInLocalStorage(message: XMPPMessage) {
        
        guard let elementReplace = message.elementForName("replace") else { return }
        guard let replaceId = elementReplace.attributeForName("id") else { return }
        
        let (moc, _) = self.getCurrentContextAndEntityDescription()
        
        let predicateFormat = "    fromMe == %@ "
        let predicate = NSPredicate(format: predicateFormat, true)
        let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: true)
        let sortDescriptors = [sortDescriptor]
        let fetchRequest = NSFetchRequest()
        
        // fetchRequest.entity = NSEntityDescription.entityForName("XMPPRoomMessageCoreDataStorageObject", inManagedObjectContext: moc )
        fetchRequest.entity = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc )
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        let error: NSError? = nil
        let results = try! moc.executeFetchRequest(fetchRequest)
        if results.isEmpty {
            print("Error fetching entity objects: \(error!.localizedDescription)\n\(error!.userInfo)")
            abort()
        }
        else {
            var done = false
            for o: Any in results {
                // TODO: extend this to MUC light using isKindOfClass
               // let thisMessageEntity = (o as! XMPPRoomMessageCoreDataStorageObject)
                 let thisMessageEntity = (o as! XMPPMessageArchiving_Message_CoreDataObject)
                let thisMessage = thisMessageEntity.message
                if  let thisMessageId = thisMessage.attributeForName("id") {
                    if replaceId.stringValue! == thisMessageId.stringValue! {
                        print("Id to replace is: \(thisMessageId.stringValue)")
                        thisMessageEntity.message = message
                        thisMessageEntity.body = message.body()
                        // thisMessageEntity.localTimestamp = localTimestamp
                        moc.refreshObject(thisMessageEntity, mergeChanges: false)
                        do {
                            try moc.save()
                        } catch {
                            fatalError("Failure to save context: \(error)")
                        }
                        
                        // TODO: test the CollectionView is bien reloaded.
                        // self.collectionView.reloadData()
                        done = true
                        break
                    }
                }
            }
            if !done {
                print("Replacement ID # \(replaceId) not found.")
            }
        }
    }
    
    private func getCurrentContextAndEntityDescription() -> (NSManagedObjectContext, NSEntityDescription?) {
        let context: NSManagedObjectContext!
        let entity: NSEntityDescription?
        
        if self.roomLight == nil {
            context = self.xmppController.xmppMessageArchivingStorage.mainThreadManagedObjectContext
            entity = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: context)
        } else {
            context = self.xmppController.xmppRoomLightCoreDataStorage.mainThreadManagedObjectContext
            entity = NSEntityDescription.entityForName("XMPPRoomLightMessageCoreDataStorageObject", inManagedObjectContext: context)
        }
        return (context, entity)
    }
    
}

// MARK: Last Message Correction
extension ChatViewController {
    // TODO: Find out if the XEP is active on the server plus if the other side client also supports this.
    internal func isLastMessageCorrectionEnabled() -> Bool {
        return true
    }
    
    func correctLastSentMessageFromMenuController(sender: UIMenuController) {
        guard self.isLastMessageCorrectionEnabled() else { return }
        
        let menuItem = sender.menuItems?.first as! MessageCorrectionUIMenuItem
        sender.menuItems = nil
        sender.update()
        
        //TODO get the xmppMessage for that id, then uncoment the following line:
        //self.correctMessage(self.xmppMessageWithID(menuItem.messageIDForCorrection))
        self.sendCorrectionMessage(self.lastMessage)
    }
    
    func xmppMessageWithID(ID: String?) -> XMPPMessage? {
        let message = XMPPMessage()
        
        guard ID != nil else {
            print("Message correction error: ID is nil")
            return nil
        }
        //TODO: find message in fetchresults
        return message
    }
    func sendCorrectionMessage(xmppMessage: XMPPMessage?) {
        guard let originalMessage = xmppMessage else { return }
        
        let alertController = UIAlertController.textFieldAlertController("Edit message", message: "Enter the text that will replace this entry") { (messageCorrectionString) in

            // we are reusing originalMessage.elementID because of the current implementation of LMC.
            if let messageCorrectionString = messageCorrectionString where messageCorrectionString.characters.count > 0 {
        
                let correctedMessage = originalMessage.generateCorrectionMessageWithID(originalMessage.elementID(), body: messageCorrectionString)
               
               //  self.replaceInLocalStorage(correctedMessage)
                self.MIMCommonInterface.sendMessage(correctedMessage)
                
                self.lastMessage = correctedMessage
                let message = self.createTextMessage(text: correctedMessage.body(), senderId: "outgoing", isIncoming: false)
                (self.chatDataSource as! ChatDataSourceInterface).addMessages([message])
            }
        }
        alertController.textFields?.first?.text = originalMessage.body()
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return action == #selector(self.correctLastSentMessageFromMenuController(_:))
    }
    
    func indexPathForLastRow () -> NSIndexPath {
        self.fetchedResultsController.sections?.count
        let lastSectionNumber = self.fetchedResultsController.sections!.count - 1
        let lastItemNumber = self.fetchedResultsController.sections!.last!.objects!.count - 1
        
        return NSIndexPath.init(forItem: lastItemNumber, inSection: lastSectionNumber)
    }
}
