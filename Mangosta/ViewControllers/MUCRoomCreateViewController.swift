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

class MUCRoomCreateViewController: UIViewController {
	@IBOutlet internal var roomNameField: UITextField!
	@IBOutlet internal var rosterTableView: UITableView!
	@IBOutlet internal var fetchedResultsController: NSFetchedResultsController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Create Room"
		
		let createButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(createRoom(_:)))
		let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(cancelCreation(_:)))
		
		self.navigationItem.rightBarButtonItems = [cancelButton, createButton]
		
		self.setupFetchedResultsController()
	}
	
	internal func createRoom(sender: UIBarButtonItem) {
		
	}
	
	internal func cancelCreation(sender: UIBarButtonItem) {
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	internal func setupFetchedResultsController() {
		if self.fetchedResultsController != nil {
			self.fetchedResultsController = nil
		}
		if let streamController = StreamManager.manager.streamController, context = streamController.rosterStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: context)
			let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
			let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
			
			let fetchRequest = NSFetchRequest()
			fetchRequest.entity = entity
			fetchRequest.sortDescriptors = [sd1, sd2]
			self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "sectionNum", cacheName: nil)
			self.fetchedResultsController?.delegate = self
			
			try! self.fetchedResultsController?.performFetch()
			
			let objects = self.fetchedResultsController?.fetchedObjects
			print(objects)
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
			cell.textLabel?.text = user.jidStr
		} else {
			cell.textLabel?.text = "nope"
		}
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let user = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPUserCoreDataStorageObject
	}
}