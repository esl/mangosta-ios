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
				self.xmppRoomsHandling(receivedRooms)
			}
		}
		StreamManager.manager.addOperation(retrieveRooms)
	}
	
	
	func xmppRoomsHandling(rooms: [XMPPRoom]) {
		self.rooms = rooms
		self.rooms.forEach { (room) in
			let joinRoomOp = XMPPRoomOperation.joinRoom(room) { (result, room) in
				print(room.isJoined)
			}
			StreamManager.manager.addOperation(joinRoomOp)
		}
		
		self.tableView.reloadData()
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
		let room = self.rooms[indexPath.row]
		
		let chatController = self.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController!
		chatController.room = room
		
		self.navigationController?.pushViewController(chatController, animated: true)
	}
}