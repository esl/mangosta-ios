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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if self.xmppController == nil {
			self.xmppController = XMPPController.sharedInstance
			
			self.xmppMUCLight?.deactivate()
			
			self.xmppMUCLight = XMPPMUCLight()
			self.xmppMUCLight.addDelegate(self, delegateQueue: DispatchQueue.main)
			self.xmppMUCLight.activate(self.xmppController.xmppStream)
		}

		self.xmppMUCLight.discoverRooms(forServiceNamed: "muclight.erlang-solutions.com")
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "createRoomViewController" {
			let createRoomViewController = segue.destination as! MUCRoomCreateViewController
			createRoomViewController.delegate = self
		}
	}
}

extension MUCLightRoomViewController: XMPPMUCLightDelegate {

	func xmppMUCLight(_ sender: XMPPMUCLight, didDiscoverRooms rooms: [DDXMLElement], forServiceNamed serviceName: String) {
		let storage = self.xmppController.xmppRoomLightCoreDataStorage

		self.xmppController.roomsLight.forEach { (room) in
			room.deactivate()
			room.removeDelegate(self)
		}

		self.xmppController.roomsLight = rooms.map { (rawElement) -> XMPPRoomLight in
			let rawJid = rawElement.attributeStringValue(forName: "jid")
			let rawName = rawElement.attributeStringValue(forName: "name")
			let jid = XMPPJID.withString(rawJid)

			let r = XMPPCustomRoomLight(roomLightStorage: storage, jid: jid!, roomname: rawName!, dispatchQueue: DispatchQueue.main)
			r.activate(self.xmppController.xmppStream)

			return r
		}
		self.tableView.reloadData()
	}
	
	func xmppMUCLight(_ sender: XMPPMUCLight, changedAffiliation affiliation: String, roomJID: XMPPJID) {
		self.xmppMUCLight.discoverRooms(forServiceNamed: "muclight.erlang-solutions.com")
	}
}

extension MUCLightRoomViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(_ sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
		sender.addUsers(self.newRoomUsers)

		self.xmppMUCLight.discoverRooms(forServiceNamed: "muclight.erlang-solutions.com")
		self.tableView.reloadData()
	}

}

extension MUCLightRoomViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(_ roomName: String, users: [XMPPJID]?) {
		self.newRoomUsers = users ?? []

		let jid = XMPPJID.withString("muclight.erlang-solutions.com")
		let roomLight = XMPPCustomRoomLight(jid: jid!, roomname: roomName)
		roomLight.addDelegate(self, delegateQueue: DispatchQueue.main)

		MIMCommonInterface.createRoomWithSubject(roomLight, name: roomName, subject: "", users: self.newRoomUsers) //users will not used  here in the xmpp version of this method.
		
		self.navigationController?.popViewController(animated: true)

	}
}

extension MUCLightRoomViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.xmppController.roomsLight.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell!
		let room = self.xmppController.roomsLight[indexPath.row]
		cell?.textLabel?.text = room.roomname()

		return cell!
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let room = self.xmppController.roomsLight[indexPath.row]

		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
		let chatController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
		chatController.roomLight = room
		chatController.xmppController = self.xmppController
		self.navigationController?.pushViewController(chatController, animated: true)
	}

	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Leave") { (UITableViewRowAction, NSIndexPath) in
			self.xmppController.roomsLight[indexPath.row].leave()
			self.xmppMUCLight.discoverRooms(forServiceNamed: "muclight.erlang-solutions.com")
		}
		leave.backgroundColor = UIColor.orange
		return [leave]
	}

	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
}
