//
//  ChatViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class ChatViewController: UIViewController {
	@IBOutlet internal var tableView: UITableView!
	var room: XMPPRoom?
	var userJID: XMPPJID?
	var fetchedResultsController: NSFetchedResultsController!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Chatting with \(self.userJID?.user ?? self.room?.roomSubject ?? "")"

		if self.userJID != nil {
			self.fetchedResultsController = self.createFetchedResultsController()
		} else {
			self.fetchedResultsController = self.createFetchedResultsControllerForGroup()
		}
		
		
		let chatButton = UIBarButtonItem(title: "Chat", style: UIBarButtonItemStyle.Done, target: self, action: #selector(showChatAlert(_:)))
		self.navigationItem.rightBarButtonItem = chatButton
	}
	
	private func createFetchedResultsControllerForGroup() -> NSFetchedResultsController {
		if let streamController = StreamManager.manager.streamController, let context = streamController.roomStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPRoomMessageCoreDataStorageObject", inManagedObjectContext: context)
			let predicate = NSPredicate(format: "jidStr = %@", self.room!.roomJID.bare())
			let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: false)
			
			let request = NSFetchRequest()
			request.entity = entity
			request.predicate = predicate
			request.sortDescriptors = [sortDescriptor]
			
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			controller.delegate = self
			try! controller.performFetch()
			
			return controller
		}
		return NSFetchedResultsController()
	}
	
	private func createFetchedResultsController() -> NSFetchedResultsController {
		if let streamController = StreamManager.manager.streamController, let context = streamController.messageArchivingStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: context)
			let predicate = NSPredicate(format: "bareJidStr = %@", self.userJID!.bare())
			let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
			
			let request = NSFetchRequest()
			request.entity = entity
			request.predicate = predicate
			request.sortDescriptors = [sortDescriptor]
			
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			controller.delegate = self
			try! controller.performFetch()
			
			return controller
		}
		return NSFetchedResultsController()
	}
	
	internal func showChatAlert(sender: AnyObject?) {
		var message = "Yo! " + "\(self.tableView.numberOfRowsInSection(0))"
		let alertController = UIAlertController(title: "Warning!", message: "It will send \(message) by default. Continue?", preferredStyle: UIAlertControllerStyle.Alert)
		
		alertController.addTextFieldWithConfigurationHandler { (textField) in
			
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
			alertController.dismissViewControllerAnimated(true, completion: nil)
		}))
		
		alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
			
			if let messageText = alertController.textFields?.first?.text where messageText.characters.count > 0 {
				message = messageText
			}

			let receiverJID = self.userJID ?? self.room?.roomJID
			let type = self.userJID != nil ? "chat" : "groupchat"
			let msg = XMPPMessage(type: type, to: receiverJID, elementID: NSUUID().UUIDString)
			msg.addBody(message)
			
			StreamManager.manager.stream.sendElement(msg)
		}))
		self.presentViewController(alertController, animated: true, completion: nil)
	}
}

extension ChatViewController: NSFetchedResultsControllerDelegate {
	//MARK: NSFetchedResultsControllerDelegate
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		self.tableView.reloadData()
	}
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
	//MARK: UITableViewDataSource, UITableViewDelegate
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if let sections = self.fetchedResultsController?.sections {
			return sections.count
		}
		return 0
	}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sections = self.fetchedResultsController?.sections
		if section < sections!.count {
			let sectionInfo = sections![section]
			return sectionInfo.numberOfObjects
		}
		return 0
	}
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		
		if userJID != nil {
			let message = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPMessageArchiving_Message_CoreDataObject
			cell.backgroundColor = message.isOutgoing ? UIColor.lightGrayColor() : UIColor.whiteColor()
			cell.textLabel?.text = message.body
			return cell
		}
		
		let message = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPRoomMessageCoreDataStorageObject
		cell.backgroundColor = message.isFromMe ? UIColor.lightGrayColor() : UIColor.whiteColor()
		cell.textLabel?.text = message.body
		return cell
	}
}
