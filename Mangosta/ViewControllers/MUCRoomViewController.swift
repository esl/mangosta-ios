//
//  MUCRoomViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 4/15/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD

class MUCRoomViewController: UIViewController {
	var fetchedResultsController: NSFetchedResultsController!
	var rooms = [XMPPRoom]()
	@IBOutlet weak var tableView: UITableView!

	override func viewDidLoad() {
		self.title = "MUC"
		super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.allowsMultipleSelectionDuringEditing = false
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		self.loadRooms(true)
	}

	func loadRooms(hud: Bool = false) {
		if hud {
			let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
			hud.labelText = "Getting rooms..."
		}
		
		let retrieveRooms = XMPPMUCOperation.retrieveRooms { rooms in
			MBProgressHUD.hideHUDForView(self.view, animated: true)
			
			if let receivedRooms = rooms {
				self.xmppRoomsHandling(receivedRooms)
			} else {
				self.xmppRoomsHandling([XMPPRoom]())
			}
		}
		StreamManager.manager.addOperation(retrieveRooms)
	}
	
	func xmppRoomsHandling(rooms: [XMPPRoom]) {
		self.rooms = rooms
		self.tableView.reloadData()
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "createRoomViewController" {
			let createRoomViewController = segue.destinationViewController as! MUCRoomCreateViewController
			createRoomViewController.delegate = self
		}
	}
}

extension MUCRoomViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(roomName: String, users: [XMPPJID]?) {
		let createRoomOperation = XMPPRoomOperation.createRoom(name: roomName) { (result, room) in
			
			let inviteUsersOperation = XMPPRoomOperation.invite(room: room, userJIDs: users!, completion: { [unowned self] (result, room) in
				self.navigationController?.popViewControllerAnimated(true)
				})
			StreamManager.manager.addOperation(inviteUsersOperation)
		}
		StreamManager.manager.addOperation(createRoomOperation)
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
				self.loadRooms()
			})
		}
		leave.backgroundColor = UIColor.orangeColor()
		return [leave]
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

}