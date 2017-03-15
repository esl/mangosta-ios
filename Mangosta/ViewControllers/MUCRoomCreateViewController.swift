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
	func createRoom(_ roomName: String, users: [XMPPJID]?)
}

class MUCRoomCreateViewController: UIViewController {
	@IBOutlet internal var roomNameField: UITextField!
	@IBOutlet internal var rosterTableView: UITableView!
	@IBOutlet internal var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!

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
	
	@IBAction func createRoom(_ sender: UIBarButtonItem) {
		self.createRoom(self.roomNameField.text!, users: Array(self.usersForRoom))
	}
	
	func createRoom(_ roomName: String, users: [XMPPJID]?) {
		self.newRoomUsers = users ?? []
		
		let jid = XMPPJID.withString("muclight.erlang-solutions.com")
		let roomLight = XMPPCustomRoomLight(jid: jid!, roomname: roomName)
		roomLight.addDelegate(self, delegateQueue: DispatchQueue.main)
		
		MIMCommonInterface.createRoomWithSubject(roomLight, name: roomName, subject: "", users: self.newRoomUsers) //users will not used  here in the xmpp version of this method.
		
		self.dismiss(animated: true, completion: nil)
		
	}
	
	@IBAction func cancelCreation(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	internal func setupFetchedResultsController() {
		if self.fetchedResultsController != nil {
			self.fetchedResultsController = nil
		}
		if let context = self.xmppController.xmppRosterStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entity(forEntityName: "XMPPUserCoreDataStorageObject", in: context)
			let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
			let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
			
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
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
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		self.rosterTableView.reloadData()
	}
}

extension MUCRoomCreateViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		if let sections = self.fetchedResultsController?.sections {
			return sections.count
		}
		return 0
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sections = self.fetchedResultsController?.sections
		if section < sections!.count {
			let sectionInfo = sections![section]
			return sectionInfo.numberOfObjects
		}
		return 0
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell!
		
		if let user = self.fetchedResultsController?.object(at: indexPath) as? XMPPUserCoreDataStorageObject {
			cell?.accessoryType = self.usersForRoom.contains(user.jid) ? .checkmark : .none
			cell?.textLabel?.text = user.jidStr
		} else {
			cell?.textLabel?.text = "nope"
		}

		return cell!
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let user = self.fetchedResultsController?.object(at: indexPath) as! XMPPUserCoreDataStorageObject
		let cell = self.rosterTableView.cellForRow(at: indexPath)
		
		if self.usersForRoom.contains(user.jid) {
			self.usersForRoom.remove(user.jid)
			cell?.accessoryType = .none
		} else {
			self.usersForRoom.insert(user.jid)
			cell?.accessoryType = .checkmark
		}
	}
}
