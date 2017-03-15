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
	var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
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

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if self.xmppController == nil {

			self.xmppController = XMPPController.sharedInstance

			self.xmppMUC?.deactivate()

			self.xmppMUC = XMPPMUC()
			self.xmppMUC.addDelegate(self, delegateQueue: DispatchQueue.main)
			self.xmppMUC.activate(self.xmppController.xmppStream)
		}
		
		self.xmppMUC.discoverRooms(forServiceNamed: "muc.erlang-solutions.com")
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "createRoomViewController" {
			let createRoomViewController = segue.destination as! MUCRoomCreateViewController
			createRoomViewController.delegate = self
		}
	}
}

extension MUCRoomViewController: XMPPMUCDelegate {
	func xmppMUC(_ sender: XMPPMUC!, didDiscoverRooms rooms: [AnyObject]!, forServiceNamed serviceName: String!) {
		guard let xmlRooms = rooms as! [DDXMLElement]! else { return }

		self.rooms.forEach { (room) in
			room.leave()
			room.deactivate()
		}

		self.rooms = xmlRooms.map { (rawElement) -> XMPPRoom in
			let rawJid = rawElement.attributeStringValue(forName: "jid")
			let rawName = rawElement.attributeStringValue(forName: "name")
			let jid = XMPPJID.withString(rawJid)

			var room: XMPPRoom?
			if jid?.domain == "muc.erlang-solutions.com" {
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
	
	func createRoom(_ roomName: String, users: [XMPPJID]?) {
		self.newRoomName = roomName
		self.newRoomUsers = users ?? []
		self.navigationController?.popToRootViewController(animated: true)
		let roomJID = XMPPJID.withUser(XMPPStream.generateUUID(), domain: "muc.erlang-solutions.com", resource: "ios")
		let room = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: roomJID)
		room?.addDelegate(self, delegateQueue: DispatchQueue.main)
		room?.activate(self.xmppController.xmppStream)
		room?.join(usingNickname: self.xmppController.xmppStream.myJID.bare(), history: nil)
	}
	
	func xmppRoomDidCreate(_ sender: XMPPRoom!) {
		let xElement = DDXMLElement(name: "x", xmlns: "jabber:x:data")
		xElement?.addAttribute(withName: "type", stringValue: "submit")
		xElement?.addChild(self.configuration("muc#roomconfig_roomname", configValue: self.newRoomName))
		xElement?.addChild(self.configuration("muc#roomconfig_persistentroom", configValue: "0"))
		sender.configureRoom(usingOptions: xElement)
		
		self.newRoomUsers.forEach { (jid) in
			sender.inviteUser(jid, withMessage: sender.roomSubject)
		}
		
		self.xmppMUC.discoverRooms(forServiceNamed: "muc.erlang-solutions.com")
	}
	
	func xmppRoomDidLeave(_ sender: XMPPRoom!) {
		self.xmppMUC.discoverRooms(forServiceNamed: "muc.erlang-solutions.com")
	}
}

extension MUCRoomViewController {
	func configuration(_ name: String, configValue: String) -> DDXMLElement {
		let value = DDXMLElement(name: "value")
		value.stringValue = configValue
		
		let field = DDXMLElement(name: "field")
		field.addAttribute(withName: "var", stringValue: name)
		field.addChild(value)
	
		return field
	}
}

extension MUCRoomViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rooms.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell!
		let room = self.rooms[indexPath.row]
		cell?.textLabel?.text = room.roomSubject

		return cell!
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let room = self.rooms[indexPath.row]

		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
		let chatController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
		room.join(usingNickname: self.xmppController.xmppStream.myJID.user, history: nil)
		chatController.room = room
		chatController.xmppController = self.xmppController
		self.navigationController?.pushViewController(chatController, animated: true)
	}

	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		
		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Leave") { (UITableViewRowAction, NSIndexPath) in
			self.rooms[indexPath.row].leave()
			self.tableView.reloadData()
		}
		leave.backgroundColor = UIColor.orange
		return [leave]
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

}
