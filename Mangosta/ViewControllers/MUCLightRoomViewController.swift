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

	weak var xmppController: XMPPController!
	var xmppMUCLight: XMPPMUCLight!
	
	let MIMCommonInterface = MIMMainInterface()

	var newRoomUsers = [XMPPJID]()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "MUCLight"

		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.allowsMultipleSelectionDuringEditing = false
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		if self.xmppController == nil {
			self.xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController
			
			self.xmppMUCLight?.deactivate()
			
			self.xmppMUCLight = XMPPMUCLight()
			self.xmppMUCLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.xmppMUCLight.activate(self.xmppController.xmppStream)
		}

		self.xmppMUCLight.discoverRoomsForServiceNamed("muclight.erlang-solutions.com")
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "createRoomViewController" {
			let createRoomViewController = segue.destinationViewController as! MUCRoomCreateViewController
			createRoomViewController.delegate = self
		}
	}
}

extension MUCLightRoomViewController: XMPPMUCLightDelegate {

	func xmppMUCLight(sender: XMPPMUCLight, didDiscoverRooms rooms: [DDXMLElement], forServiceNamed serviceName: String) {
		let storage = self.xmppController.xmppRoomLightCoreDataStorage

		self.xmppController.roomsLight.forEach { (room) in
			room.deactivate()
			room.removeDelegate(self)
		}

		self.xmppController.roomsLight = rooms.map { (rawElement) -> XMPPRoomLight in
			let rawJid = rawElement.attributeStringValueForName("jid")
			let rawName = rawElement.attributeStringValueForName("name")
			let jid = XMPPJID.jidWithString(rawJid)

			let r = XMPPCustomRoomLight(roomLightStorage: storage, jid: jid, roomname: rawName, dispatchQueue: dispatch_get_main_queue())
			r.activate(self.xmppController.xmppStream)

			return r
		}
		self.tableView.reloadData()
	}
	
	func xmppMUCLight(sender: XMPPMUCLight, changedAffiliation affiliation: String, roomJID: XMPPJID) {
		self.xmppMUCLight.discoverRoomsForServiceNamed("muclight.erlang-solutions.com")
	}
}

extension MUCLightRoomViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
		sender.addUsers(self.newRoomUsers)

		self.xmppMUCLight.discoverRoomsForServiceNamed("muclight.erlang-solutions.com")
		self.tableView.reloadData()
	}

}

extension MUCLightRoomViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(roomName: String, users: [XMPPJID]?) {
		self.newRoomUsers = users ?? []

		let jid = XMPPJID.jidWithString("muclight.erlang-solutions.com")
		let roomLight = XMPPCustomRoomLight(JID: jid!, roomname: roomName)
		roomLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())

		MIMCommonInterface.createRoomWithSubject(roomLight, name: roomName, subject: "", users: self.newRoomUsers) //users will not used  here in the xmpp version of this method.
		
		self.navigationController?.popViewControllerAnimated(true)

	}
}

extension MUCLightRoomViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.xmppController.roomsLight.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		let room = self.xmppController.roomsLight[indexPath.row]
		cell.textLabel?.text = room.roomname()

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let room = self.xmppController.roomsLight[indexPath.row]

		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
		let chatController = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
		chatController.roomLight = room
		chatController.xmppController = self.xmppController
		self.navigationController?.pushViewController(chatController, animated: true)
	}

	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Leave") { (UITableViewRowAction, NSIndexPath) in
			self.xmppController.roomsLight[indexPath.row].leaveRoomLight()
			self.xmppMUCLight.discoverRoomsForServiceNamed("muclight.erlang-solutions.com")
		}
		leave.backgroundColor = UIColor.orangeColor()
		return [leave]
	}

	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
}