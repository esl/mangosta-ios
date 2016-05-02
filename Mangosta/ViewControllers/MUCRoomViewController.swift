//
//  MUCRoomViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 4/15/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class MUCRoomViewController: UIViewController {
	var fetchedResultsController: NSFetchedResultsController!
	var rooms = [XMPPRoom]()
	@IBOutlet weak var tableView: UITableView!

	override func viewDidLoad() {
		self.title = "MUC Room"
		super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		let retrieveRooms = XMPPMUCOperation.retrieveRooms { rooms in
			if let receivedRooms = rooms {
				self.rooms = receivedRooms
				self.tableView.reloadData()
			}
		}
		StreamManager.manager.addOperation(retrieveRooms)
	}
}

extension MUCRoomViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rooms.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		let room = self.rooms[indexPath.row]
		cell.textLabel?.text = room.roomSubject

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		print("hi")
	}
}