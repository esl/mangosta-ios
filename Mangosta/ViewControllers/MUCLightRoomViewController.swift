//
//  MUCLightRoomViewController.swift
//  Mangosta
//
//  Created by Andres Canal on 5/17/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class MUCLightRoomViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.allowsMultipleSelectionDuringEditing = false
		
		self.title = "MUCLight"
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
		
		print("CREATE MUCLIGHT")
		
	}
}

extension MUCLightRoomViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		print("Room selected")
	}
	
	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
//		
//		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Leave"){(UITableViewRowAction,NSIndexPath) in
//			let room = self.rooms[indexPath.row]
//			StreamManager.manager.addOperation(XMPPRoomOperation.leave(room: room){ result in
//				self.tableView.reloadData()
//				})
//		}
//		leave.backgroundColor = UIColor.orangeColor()
//		return [leave]
		return nil
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
}