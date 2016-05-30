//
//  MUCLightRoomViewController.swift
//  Mangosta
//
//  Created by Andres Canal on 5/17/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD

class MUCLightRoomViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	var rooms = [XMPPRoomLight]()

    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.allowsMultipleSelectionDuringEditing = false
		
		self.title = "MUCLight"
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

		let retrieveRooms = XMPPMUCLightOperation.retrieveRooms{ rooms in
			MBProgressHUD.hideHUDForView(self.view, animated: true)
			
			if let receivedRooms = rooms {
				self.xmppRoomsHandling(receivedRooms)
			} else {
				self.xmppRoomsHandling([XMPPRoomLight]())
			}
		}
		StreamManager.manager.addOperation(retrieveRooms)
	}
	
	func xmppRoomsHandling(rooms: [XMPPRoomLight]) {
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

extension MUCLightRoomViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(roomName: String, users: [XMPPJID]?) {
		
		let createRoomOperation = XMPPRoomLightOperation.createRoom(name: roomName, members: users) { (result, room) in
			self.navigationController?.popViewControllerAnimated(true)
		}
		StreamManager.manager.addOperation(createRoomOperation)
	}
}

extension MUCLightRoomViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rooms.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		let room = self.rooms[indexPath.row]
		cell.textLabel?.text = room.roomname

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let room = self.rooms[indexPath.row]

		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
		let chatController = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
		chatController.roomLight = room

		self.navigationController?.pushViewController(chatController, animated: true)
	}

	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Leave"){(UITableViewRowAction,NSIndexPath) in
			let room = self.rooms[indexPath.row]
			StreamManager.manager.addOperation(XMPPRoomLightOperation.leaveRoom(room: room, completion: { (result) in
//				self.loadRooms()
			}))
		}
		leave.backgroundColor = UIColor.orangeColor()
		return [leave]
	}

	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
}