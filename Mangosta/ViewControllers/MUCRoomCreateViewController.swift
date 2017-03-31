//
//  MUCRoomCreateViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 4/15/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import CoreData
import XMPPFramework

protocol MUCRoomCreateViewControllerDelegate: class {
	func createRoom(roomName: String, users: [XMPPJID]?)
}

class MUCRoomCreateViewController: UIViewController {
	@IBOutlet internal var roomNameField: UITextField!
	@IBOutlet internal var rosterTableView: UITableView!
	@IBOutlet internal var fetchedResultsController: NSFetchedResultsController!

	weak var xmppController: XMPPController!
	
	let MIMCommonInterface = MIMMainInterface()
	
	var newRoomUsers = [XMPPJID]()
	
	var usersForRoom = Set<XMPPJID>()
	weak var delegate: MUCRoomCreateViewControllerDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Create Room"

		self.xmppController = XMPPController.sharedInstance
		
		self.setupFetchedResultsController()
	}
	
	@IBAction func createRoom(sender: UIBarButtonItem) {
        delegate?.createRoom(roomNameField.text!, users: Array(usersForRoom))
	}
	
	@IBAction func cancelCreation(sender: UIBarButtonItem) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	internal func setupFetchedResultsController() {
		if self.fetchedResultsController != nil {
			self.fetchedResultsController = nil
		}
		if let context = self.xmppController.xmppRosterStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: context)
			let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
			let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
			
			let fetchRequest = NSFetchRequest()
			fetchRequest.entity = entity
			fetchRequest.sortDescriptors = [sd1, sd2]
			self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "sectionNum", cacheName: nil)
			self.fetchedResultsController?.delegate = self
			
			try! self.fetchedResultsController?.performFetch()
			self.rosterTableView.reloadData()
		}
	}

}

extension MUCRoomCreateViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.rosterTableView.reloadData()
	}
}

extension MUCRoomCreateViewController: UITableViewDelegate, UITableViewDataSource {
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
		
		if let user = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? XMPPUserCoreDataStorageObject {
			cell?.accessoryType = self.usersForRoom.contains(user.jid) ? .Checkmark : .None
			cell.textLabel?.text = user.jidStr
		} else {
			cell.textLabel?.text = "nope"
		}

		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let user = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPUserCoreDataStorageObject
		let cell = self.rosterTableView.cellForRowAtIndexPath(indexPath)
		
		if self.usersForRoom.contains(user.jid) {
			self.usersForRoom.remove(user.jid)
			cell?.accessoryType = .None
		} else {
			self.usersForRoom.insert(user.jid)
			cell?.accessoryType = .Checkmark
		}
	}
}
