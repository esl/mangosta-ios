//
//  ViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/11/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD

class MainViewController: UIViewController, titleViewModifiable {
   
	@IBOutlet internal var tableView: UITableView!
	var fetchedResultsController: NSFetchedResultsController?
	var activated = true
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
	
    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String? = "Chats"
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }
    
	override func viewDidLoad() {
        
        self.xmppController = XMPPController.sharedInstance
        
		let darkGreenColor = "009ab5"
		let lightGreenColor = "58cfe4"
	
		let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(selectChat(_:)))
		addButton.tintColor = UIColor(hexString:darkGreenColor)
		self.navigationItem.rightBarButtonItems = [addButton]
		 
		let meButton = UIBarButtonItem(image: UIImage(named: "Gear"), style: UIBarButtonItemStyle.Done, target: self, action: #selector(pushMeViewControler(_:)))
		meButton.tintColor =  UIColor(hexString:darkGreenColor)
		self.navigationItem.leftBarButtonItem = meButton
		
		MangostaSettings().setNavigationBarColor()
		
		self.tableView.backgroundColor = UIColor(hexString:lightGreenColor)

        self.tabBarItem.image = UIImage(named: "Chat") // FIXME: no image is appearing
        self.tabBarItem.selectedImage = UIImage(named: "Chat Filled") // FIXME: no image is appearing
        
        self.title = self.originalTitleViewText
        
        if AuthenticationModel.load() == nil {
            presentLogInView()
        } else {
                self.setupDataSources()
        }
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.xmppController.xmppStream.isAuthenticated() {
            self.resetTitleViewTextToOriginal()
            
        }
        else {
            let titleLabel = UILabel()
            titleLabel.text = "Connecting"
            self.navigationItem.titleView = titleLabel
            titleLabel.sizeToFit()
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        guard self.xmppController.xmppStream.isAuthenticated() else { return }
        
        try! self.fetchedResultsController?.performFetch()
        self.xmppMUCLight?.discoverRoomsForServiceNamed(MUCLightServiceName)
        super.viewDidAppear(animated)
    }
	
	func presentLogInView() {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
		let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController

		self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
	}
	
	// TODO: this is for implementing later in the UI: XEP-0352: Client State Indication
	@IBAction func activateDeactivate(sender: UIButton) {
		if activated {
			self.xmppController.xmppStream.sendElement(XMPPElement.indicateInactiveElement())
			self.activated = false
			sender.setTitle("activate", forState: UIControlState.Normal)
		} else {
			self.xmppController.xmppStream.sendElement(XMPPElement.indicateActiveElement())
			self.activated = true
			sender .setTitle("deactivate", forState: UIControlState.Normal)
		}
	}
	
	func pushMeViewControler(sender: UIBarButtonItem) {
		let storyboard = UIStoryboard(name: "Me", bundle: nil)
		let meController = storyboard.instantiateViewControllerWithIdentifier("MeViewController") as! Me
		meController.xmppController = self.xmppController
		self.navigationController?.pushViewController(meController, animated: true)
	}
	
	func selectChat(sender: UIBarButtonItem) {
		let alertController = UIAlertController(title: nil, message: "New Chat", preferredStyle: .ActionSheet)
		alertController.view.tintColor = UIColor(hexString:"009ab5")
		let roomChatAction = UIAlertAction(title: "New Room Chat", style: .Default) { (action) in
			let storyboard = UIStoryboard(name: "MUCLight", bundle: nil)
			let roomCreateViewController = storyboard.instantiateViewControllerWithIdentifier("MUCLightCreateRoomPresenterViewController") as! UINavigationController
			self.presentViewController(roomCreateViewController, animated: true, completion: nil)
		}
		alertController.addAction(roomChatAction)
		
		let privateChatAction = UIAlertAction(title: "New Private Chat", style: .Default) { (action) in
			self.createNewFriendChat(sender)
		}
		alertController.addAction(privateChatAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .Destructive) { (action) in
			
		}
		alertController.addAction(cancelAction)
		
		self.presentViewController(alertController, animated: true) {
			
		}
	}
	func createNewFriendChat(sender: UIBarButtonItem) {
		let alertController = UIAlertController.textFieldAlertController("New Conversation", message: "Enter the JID of the user or group name") { (jidString) in
			guard let userJIDString = jidString, let userJID = XMPPJID.jidWithString(userJIDString) else { return }
			self.xmppController?.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	internal func setupDataSources() {
		
		let rosterContext = self.xmppController.managedObjectContext_roster()
		
		let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: rosterContext)
		let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
		let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
		
		let fetchRequest = NSFetchRequest()
		fetchRequest.entity = entity
		fetchRequest.sortDescriptors = [sd1, sd2]
		self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: rosterContext, sectionNameKeyPath: "sectionNum", cacheName: nil)
		self.fetchedResultsController?.delegate = self
		
		self.xmppMUCLight = XMPPMUCLight()
		self.xmppMUCLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		self.xmppMUCLight.activate(self.xmppController.xmppStream)
		
		self.tableView.reloadData()
	}
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return sections.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard section < self.sections.count else {
			return 0
		}
		switch section {
		case 0:
			return self.xmppController?.roomsLight.count ?? 0
			
		case 1:
			guard let controller = self.fetchedResultsController else {
				return 0
			}
			return controller.sections?.first?.numberOfObjects ?? 0
		default:
			return 0
		}
	}

	func tableView(tableView : UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}
	
	func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let header = view as? UITableViewHeaderFooterView
		header?.tintColor = UIColor.whiteColor()
		header?.textLabel?.textColor = UIColor(hexString:"009ab5")
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		
		if indexPath.section == 1 {
			let privateChatsIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
			if let user = self.fetchedResultsController?.objectAtIndexPath(privateChatsIndexPath) as? XMPPUserCoreDataStorageObject {
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
		}
		else if indexPath.section == 0 {
			if self.xmppController.roomsLight.count > 0 {
				let room = self.xmppController.roomsLight[indexPath.row]
				cell.textLabel?.text = room.roomname()
			}
			else {
				cell.textLabel?.text = "No rooms"
			}
		}
		
		cell.backgroundColor = UIColor(hexString:"009ab5")
		cell.textLabel?.textColor = UIColor.whiteColor()
		cell.textLabel?.font = UIFont.boldSystemFontOfSize(15.0)
		cell.detailTextLabel?.textColor = UIColor.whiteColor()
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard indexPath.section <= 1 else { return }
		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
		let chatController = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
		
		if indexPath.section == 0 {
			let room = self.xmppController.roomsLight[indexPath.row]
			
			chatController.roomLight = room
			chatController.xmppController = self.xmppController
			
		}
		else if indexPath.section == 1 {
			let useThisIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
			let user = self.fetchedResultsController?.objectAtIndexPath(useThisIndexPath) as! XMPPUserCoreDataStorageObject
			
			chatController.xmppController = self.xmppController
			chatController.userJID = user.jid
			
		}
		self.navigationController?.pushViewController(chatController, animated: true)
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
		if indexPath.section  == 0 {
			
			let leave = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Leave") { (UITableViewRowAction, NSIndexPath) in
				
				self.xmppController.roomsLight[indexPath.row].leaveRoomLight()
			}
			leave.backgroundColor = UIColor.orangeColor()
			
			leaveArray.append(leave)
		}
			
		else if indexPath.section == 1 {
			let privateChatsIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
			let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") { (UITableViewRowAction, NSIndexPath) in
				
				let rosterContext = self.xmppController.managedObjectContext_roster()
				
				if let user = self.fetchedResultsController?.objectAtIndexPath(privateChatsIndexPath) as? XMPPUserCoreDataStorageObject {
					rosterContext.deleteObject(user as NSManagedObject)
				}
				
				do {
					try rosterContext.save()
				} catch {
					print("Error saving roster context: \(error)")
				}
			}
			
			delete.backgroundColor = UIColor.redColor()
			leaveArray.append(delete)
		}
		
		return leaveArray
	}

	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

}

extension MainViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.reloadData()
	}
}

extension MainViewController: XMPPMUCLightDelegate {
	
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
		self.xmppMUCLight?.discoverRoomsForServiceNamed(MUCLightServiceName)
	}
}

extension MainViewController: MUCRoomCreateViewControllerDelegate {
	
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
extension MainViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
		sender.addUsers(self.newRoomUsers)
		
		self.xmppMUCLight.discoverRoomsForServiceNamed(MUCLightServiceName)
		self.tableView.reloadData()
	}
}


