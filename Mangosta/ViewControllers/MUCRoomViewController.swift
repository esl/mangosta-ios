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
		self.tableView.allowsMultipleSelectionDuringEditing = false
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

		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
		let chatController = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
		chatController.room = room

		if !room.isJoined {
			let joinRoomOp = XMPPRoomOperation.joinRoom(room) { (result, room) in
				if result {
					print("Joined Room: \(room.roomSubject)")
				} else {
					print("Failed to Join Room: \(room.roomSubject)")
				}
			}
			StreamManager.manager.addOperation(joinRoomOp)
		}

		self.navigationController?.pushViewController(chatController, animated: true)
	}

	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		
		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Leave"){(UITableViewRowAction,NSIndexPath) in
			let room = self.rooms[indexPath.row]
			StreamManager.manager.addOperation(XMPPRoomOperation.leave(room: room){ result in
				self.tableView.reloadData()
			})
		}
		leave.backgroundColor = UIColor.orangeColor()
		return [leave]
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

}