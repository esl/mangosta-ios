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
	weak var xmppController: XMPPController!
	var xmppMUC: XMPPMUC!
	
	var newRoomName: String = ""
	var newRoomUsers = [XMPPJID]()

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

		if self.xmppController == nil {

			self.xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController

			self.xmppMUC?.deactivate()

			self.xmppMUC = XMPPMUC()
			self.xmppMUC.addDelegate(self, delegateQueue: dispatch_get_main_queue())
			self.xmppMUC.activate(self.xmppController.xmppStream)
		}
		
		self.xmppMUC.discoverRoomsForServiceNamed("muc.erlang-solutions.com")
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "createRoomViewController" {
			let createRoomViewController = segue.destinationViewController as! MUCRoomCreateViewController
			createRoomViewController.delegate = self
		}
	}
}

extension MUCRoomViewController: XMPPMUCDelegate {
	func xmppMUC(sender: XMPPMUC!, didDiscoverRooms rooms: [AnyObject]!, forServiceNamed serviceName: String!) {
		guard let xmlRooms = rooms as! [DDXMLElement]! else { return }

		self.rooms.forEach { (room) in
			room.leaveRoom()
			room.deactivate()
		}

		self.rooms = xmlRooms.map { (rawElement) -> XMPPRoom in
			let rawJid = rawElement.attributeStringValueForName("jid")
			let rawName = rawElement.attributeStringValueForName("name")
			let jid = XMPPJID.jidWithString(rawJid)

			var room: XMPPRoom?
			if jid.domain == "muc.erlang-solutions.com" {
				room = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: jid)
			}
			room?.activate(self.xmppController.xmppStream)
			room!.setValue(rawName, forKey: "roomSubject")
			return room!
		}
		self.tableView.reloadData()
	}
}

extension MUCRoomViewController: MUCRoomCreateViewControllerDelegate, XMPPRoomDelegate {
	
	func createRoom(roomName: String, users: [XMPPJID]?) {
		self.newRoomName = roomName
		self.newRoomUsers = users ?? []
		self.navigationController?.popToRootViewControllerAnimated(true)
		let roomJID = XMPPJID.jidWithUser(XMPPStream.generateUUID(), domain: "muc.erlang-solutions.com", resource: "ios")
		let room = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: roomJID)
		room.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		room.activate(self.xmppController.xmppStream)
		room.joinRoomUsingNickname(self.xmppController.xmppStream.myJID.bare(), history: nil)
	}
	
	func xmppRoomDidCreate(sender: XMPPRoom!) {
		let xElement = DDXMLElement(name: "x", xmlns: "jabber:x:data")
		xElement.addAttributeWithName("type", stringValue: "submit")
		xElement.addChild(self.configuration("muc#roomconfig_roomname", configValue: self.newRoomName))
		xElement.addChild(self.configuration("muc#roomconfig_persistentroom", configValue: "0"))
		sender.configureRoomUsingOptions(xElement)
		
		self.newRoomUsers.forEach { (jid) in
			sender.inviteUser(jid, withMessage: sender.roomSubject)
		}
		
		self.xmppMUC.discoverRoomsForServiceNamed("muc.erlang-solutions.com")
	}
	
	func xmppRoomDidLeave(sender: XMPPRoom!) {
		self.xmppMUC.discoverRoomsForServiceNamed("muc.erlang-solutions.com")
	}
}

extension MUCRoomViewController {
	func configuration(name: String, configValue: String) -> DDXMLElement {
		let value = DDXMLElement(name: "value")
		value.setStringValue(configValue)
		
		let field = DDXMLElement(name: "field")
		field.addAttributeWithName("var", stringValue: name)
		field.addChild(value)
	
		return field
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
		room.joinRoomUsingNickname(self.xmppController.xmppStream.myJID.user, history: nil)
		chatController.room = room
		chatController.xmppController = self.xmppController
		self.navigationController?.pushViewController(chatController, animated: true)
	}

	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		
		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Leave") { (UITableViewRowAction, NSIndexPath) in
			self.rooms[indexPath.row].leaveRoom()
			self.tableView.reloadData()
		}
		leave.backgroundColor = UIColor.orangeColor()
		return [leave]
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

}
