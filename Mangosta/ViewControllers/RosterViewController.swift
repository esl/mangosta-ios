//
//  RosterController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/11/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD

class RosterViewController: UIViewController {
	@IBOutlet internal var tableView: UITableView!
	var fetchedResultsController: NSFetchedResultsController?
	
	weak var xmppController: XMPPController!
	
	#if MangostaREST // TODO: probably better way.
	weak var mongooseRESTController : MongooseAPI!
	#endif
	
	let sections = ["Group chats", "Private chats"]
	
	let MIMCommonInterface = MIMMainInterface()
	
	var xmppMUCLight: XMPPMUCLight!
	
	var newRoomUsers = [XMPPJID]()
	
	var localDataSource = NSMutableArray()
	
	let MUCLightServiceName = "muclight.erlang-solutions.com" // TODO: use a .plist entry for all constants in this app.
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(addRoster(_:)))
	self.navigationItem.rightBarButtonItems = [addButton]
		
		if AuthenticationModel.load() == nil {
			presentLogInView()
		} 
		
	}
	
	override func viewDidAppear(animated: Bool) {
		self.xmppMUCLight?.discoverRoomsForServiceNamed(MUCLightServiceName)
	}
	
	func presentLogInView() {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
		let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		loginController.loginDelegate = self
		self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
	}
	
	override func viewWillAppear(animated: Bool) {
		
		super.viewWillAppear(animated)
		if self.xmppController == nil {
			
			self.xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController
			self.setupDataSources()
		}
	}
	
	func pushMeViewControler(sender: UIBarButtonItem) {
		let storyboard = UIStoryboard(name: "Me", bundle: nil)
		let meController = storyboard.instantiateViewControllerWithIdentifier("MeViewController") as! Me
		meController.xmppController = self.xmppController
		self.navigationController?.pushViewController(meController, animated: true)
	}
	
	func addRoster(sender: UIBarButtonItem){
		let alertController = UIAlertController.textFieldAlertController("Add Friend", message: "Enter the JID of the user") { (jidString) in
			guard let userJIDString = jidString, userJID = XMPPJID.jidWithString(userJIDString) else { return }
			self.xmppController.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	func removeRoster(userJID: XMPPJID ){
		self.xmppController.xmppRoster.removeUser(userJID) // TODO: revise callback
	}

	
	func createNewFriendChat(sender: UIBarButtonItem) {
		let alertController = UIAlertController.textFieldAlertController("New Conversation", message: "Enter the JID of the user or group name") { (jidString) in
			guard let userJIDString = jidString, userJID = XMPPJID.jidWithString(userJIDString) else { return }
			self.xmppController.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	func editTable(sender: UIBarButtonItem) {
		
	}
	
	internal func setupDataSources() {
		
		let rosterContext = self.xmppController.xmppRosterStorage.mainThreadManagedObjectContext
		
		let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: rosterContext)
		let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
		let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
		
		let fetchRequest = NSFetchRequest()
		fetchRequest.entity = entity
		fetchRequest.sortDescriptors = [sd1, sd2]
		self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: rosterContext, sectionNameKeyPath: "sectionNum", cacheName: nil)
		self.fetchedResultsController?.delegate = self
		
		try! self.fetchedResultsController?.performFetch()
		
		self.tableView.reloadData()
	}
}

extension RosterViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if let sections = self.fetchedResultsController?.sections {
			return sections.count
		}
		return 0
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sections = self.fetchedResultsController?.sections
		if section < sections!.count {
			let sectionInfo = sections![section]
			return sectionInfo.numberOfObjects
		}
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		
		if let user = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? XMPPUserCoreDataStorageObject {
			if let firstResource = user.resources.first {
				if let pres = firstResource.valueForKey("presence") {
					if pres.type == "available" {
						cell.textLabel?.textColor = UIColor.blueColor()
					} else {
						cell.textLabel?.textColor = UIColor.darkGrayColor()
					}
					
				}
			} else {
				cell.textLabel?.textColor = UIColor.darkGrayColor()
			}
			
			cell.textLabel?.text = user.jidStr
		} else {
			cell.textLabel?.text = "nope"
		}
		
		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard indexPath.section == 0 else { return }
		
		let useThisIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
		let user = self.fetchedResultsController?.objectAtIndexPath(useThisIndexPath) as! XMPPUserCoreDataStorageObject
		
		self.removeRoster(user.jid)
	}
	
	func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
		// TODO: use safe optionals
		let item = self.fetchedResultsController?.objectAtIndexPath(sourceIndexPath)
		var items = self.fetchedResultsController?.fetchedObjects
		items?.removeAtIndex(sourceIndexPath.row)
		items?.insert(item!, atIndex: destinationIndexPath.row)
	}
	
	func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		var leaveArray : [UITableViewRowAction] = []
		let privateChatsIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
		let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") { (UITableViewRowAction, NSIndexPath) in
			
			let rosterContext = self.xmppController.xmppRosterStorage.mainThreadManagedObjectContext
			
			if let user = self.fetchedResultsController?.objectAtIndexPath(privateChatsIndexPath) as? XMPPUserCoreDataStorageObject {
				self.removeRoster(user.jid)
			}
			
			do {
				try rosterContext.save()
			} catch {
				print("Error saving roster context: \(error)")
			}
		}
		
		delete.backgroundColor = UIColor.redColor()
		leaveArray.append(delete)
		
		return leaveArray
	}

	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

}

extension RosterViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.reloadData()
	}
}

extension RosterViewController: LoginControllerDelegate {
	func didLogIn() {
		self.setupDataSources() // and MongooseREST API
	}
}

extension RosterViewController: XMPPMUCLightDelegate {
	
	func xmppMUCLight(sender: XMPPMUCLight, didDiscoverRooms rooms: [DDXMLElement], forServiceNamed serviceName: String) {
		guard self.xmppController != nil else { return }
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
		self.xmppMUCLight?.discoverRoomsForServiceNamed(MUCLightServiceName)
	}
}

extension RosterViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(roomName: String, users: [XMPPJID]?) {
		self.newRoomUsers = users ?? []
		
		let jid = XMPPJID.jidWithString(MUCLightServiceName)
		let roomLight = XMPPCustomRoomLight(JID: jid!, roomname: roomName)
		roomLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		MIMCommonInterface.createRoomWithSubject(roomLight, name: roomName, subject: "", users: self.newRoomUsers) //users will not used  here in the xmpp version of this method.
		
		self.navigationController?.popViewControllerAnimated(true)
		
	}
}
// FIXME: create room
extension RosterViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
		sender.addUsers(self.newRoomUsers)
		
		self.xmppMUCLight.discoverRoomsForServiceNamed(MUCLightServiceName)
		self.tableView.reloadData()
	}
}

