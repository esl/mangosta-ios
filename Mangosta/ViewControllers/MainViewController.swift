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

class MainViewController: UIViewController, TitleViewModifiable {
   
	@IBOutlet internal var tableView: UITableView!
	var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
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
	
		let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(selectChat(_:)))
		addButton.tintColor = UIColor(hexString:darkGreenColor)
		self.navigationItem.rightBarButtonItems = [addButton]
		 
		let meButton = UIBarButtonItem(image: UIImage(named: "Gear"), style: UIBarButtonItemStyle.done, target: self, action: #selector(pushMeViewControler(_:)))
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
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard self.xmppController.xmppStream.isAuthenticated() else { return }
        
        try! self.fetchedResultsController?.performFetch()
        self.xmppMUCLight?.discoverRooms(forServiceNamed: MUCLightServiceName)
        super.viewDidAppear(animated)
    }
	
	func presentLogInView() {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
		let loginController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController

		self.navigationController?.present(loginController, animated: true, completion: nil)
	}
	
	// TODO: this is for implementing later in the UI: XEP-0352: Client State Indication
	@IBAction func activateDeactivate(_ sender: UIButton) {
		if activated {
			self.xmppController.xmppStream.send(XMPPElement.indicateInactive())
			self.activated = false
			sender.setTitle("activate", for: UIControlState())
		} else {
			self.xmppController.xmppStream.send(XMPPElement.indicateActive())
			self.activated = true
			sender .setTitle("deactivate", for: UIControlState())
		}
	}
	
	func pushMeViewControler(_ sender: UIBarButtonItem) {
		let storyboard = UIStoryboard(name: "Me", bundle: nil)
		let meController = storyboard.instantiateViewController(withIdentifier: "MeViewController") as! Me
		meController.xmppController = self.xmppController
		self.navigationController?.pushViewController(meController, animated: true)
	}
	
	func selectChat(_ sender: UIBarButtonItem) {
		let alertController = UIAlertController(title: nil, message: "New Chat", preferredStyle: .actionSheet)
		alertController.view.tintColor = UIColor(hexString:"009ab5")
		let roomChatAction = UIAlertAction(title: "New Room Chat", style: .default) { (action) in
			let storyboard = UIStoryboard(name: "MUCLight", bundle: nil)
			let roomCreateViewController = storyboard.instantiateViewController(withIdentifier: "MUCLightCreateRoomPresenterViewController") as! UINavigationController
			self.present(roomCreateViewController, animated: true, completion: nil)
		}
		alertController.addAction(roomChatAction)
		
		let privateChatAction = UIAlertAction(title: "New Private Chat", style: .default) { (action) in
			self.createNewFriendChat(sender)
		}
		alertController.addAction(privateChatAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
			
		}
		alertController.addAction(cancelAction)
		
		self.present(alertController, animated: true) {
			
		}
	}
	func createNewFriendChat(_ sender: UIBarButtonItem) {
		let alertController = UIAlertController.textFieldAlertController("New Conversation", message: "Enter the JID of the user or group name") { (jidString) in
            guard let userJIDString = jidString, let userJID = XMPPJID.init(string: userJIDString) else { return }
			self.xmppController?.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.present(alertController, animated: true, completion: nil)
	}
	
	internal func setupDataSources() {
		
		let rosterContext = self.xmppController.managedObjectContext_roster()
		
		let entity = NSEntityDescription.entity(forEntityName: "XMPPUserCoreDataStorageObject", in: rosterContext)
		let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
		let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
		
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
		fetchRequest.entity = entity
		fetchRequest.sortDescriptors = [sd1, sd2]
		self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: rosterContext, sectionNameKeyPath: "sectionNum", cacheName: nil)
		self.fetchedResultsController?.delegate = self
		
		self.xmppMUCLight = XMPPMUCLight()
		self.xmppMUCLight.addDelegate(self, delegateQueue: DispatchQueue.main)
		self.xmppMUCLight.activate(self.xmppController.xmppStream)
		
		self.tableView.reloadData()
	}
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

	func tableView(_ tableView : UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let header = view as? UITableViewHeaderFooterView
		header?.tintColor = UIColor.white
		header?.textLabel?.textColor = UIColor(hexString:"009ab5")
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell!
		
		if indexPath.section == 1 {
			let privateChatsIndexPath = IndexPath(row: indexPath.row, section: 0)
			if let user = self.fetchedResultsController?.object(at: privateChatsIndexPath) as? XMPPUserCoreDataStorageObject {
				if let firstResource = user.resources.first as? XMPPResource {
					if let pres = firstResource.presence() {
						if pres.type() == "available" {
							cell?.textLabel?.textColor = UIColor.blue
						} else {
							cell?.textLabel?.textColor = UIColor.darkGray
						}
					}
				} else {
					cell?.textLabel?.textColor = UIColor.darkGray
				}
				
				cell?.textLabel?.text = user.jidStr
			} else {
				cell?.textLabel?.text = "nope"
			}
		}
		else if indexPath.section == 0 {
			if self.xmppController.roomsLight.count > 0 {
				let room = self.xmppController.roomsLight[indexPath.row]
				cell?.textLabel?.text = room.roomname()
			}
			else {
				cell?.textLabel?.text = "No rooms"
			}
		}
		
		cell?.backgroundColor = UIColor(hexString:"009ab5")
		cell?.textLabel?.textColor = UIColor.white
		cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
		cell?.detailTextLabel?.textColor = UIColor.white
		
		return cell!
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.section <= 1 else { return }
		let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        
		let chatController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController

		if indexPath.section == 0 {
			let room = self.xmppController.roomsLight[indexPath.row]
			
			chatController.roomLight = room
			chatController.xmppController = self.xmppController
			
		}
		else if indexPath.section == 1 {
			let useThisIndexPath = IndexPath(row: indexPath.row, section: 0)
			let user = self.fetchedResultsController?.object(at: useThisIndexPath) as! XMPPUserCoreDataStorageObject
			
			chatController.xmppController = self.xmppController
			chatController.userJID = user.jid
			
		}
		self.navigationController?.pushViewController(chatController, animated: true)
	}
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		// TODO: use safe optionals
		let item = self.fetchedResultsController?.object(at: sourceIndexPath)
		var items = self.fetchedResultsController?.fetchedObjects
		items?.remove(at: sourceIndexPath.row)
		items?.insert(item!, at: destinationIndexPath.row)
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		var leaveArray : [UITableViewRowAction] = []
		if indexPath.section  == 0 {
			
			let leave = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Leave") { (UITableViewRowAction, IndexPath) in
				
				self.xmppController.roomsLight[indexPath.row].leave()
			}
			leave.backgroundColor = UIColor.orange
			
			leaveArray.append(leave)
		}
			
		else if indexPath.section == 1 {
			let privateChatsIndexPath = IndexPath(row: indexPath.row, section: 0)
			let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { (UITableViewRowAction, IndexPath) in
				
				let rosterContext = self.xmppController.managedObjectContext_roster()
				
				if let user = self.fetchedResultsController?.object(at: privateChatsIndexPath) as? XMPPUserCoreDataStorageObject {
					rosterContext.delete(user as NSManagedObject)
				}
				
				do {
					try rosterContext.save()
				} catch {
					print("Error saving roster context: \(error)")
				}
			}
			
			delete.backgroundColor = UIColor.red
			leaveArray.append(delete)
		}
		
		return leaveArray
	}

	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

}

extension MainViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		self.tableView.reloadData()
	}
}

extension MainViewController: XMPPMUCLightDelegate {
	
	func xmppMUCLight(_ sender: XMPPMUCLight, didDiscoverRooms rooms: [DDXMLElement], forServiceNamed serviceName: String) {

		let storage = self.xmppController.xmppRoomLightCoreDataStorage
		
		self.xmppController.roomsLight.forEach { (room) in
			room.deactivate()
			room.removeDelegate(self)
		}
		
		self.xmppController.roomsLight = rooms.map { (rawElement) -> XMPPRoomLight in
			let rawJid = rawElement.attributeStringValue(forName: "jid")
			let rawName = rawElement.attributeStringValue(forName: "name")
			let jid = XMPPJID.init(string: rawJid)
			
			let r = XMPPCustomRoomLight(roomLightStorage: storage, jid: jid!, roomname: rawName!, dispatchQueue: DispatchQueue.main)
			r.activate(self.xmppController.xmppStream)
			
			return r
		}
		self.tableView.reloadData()
	}
	
	func xmppMUCLight(_ sender: XMPPMUCLight, changedAffiliation affiliation: String, roomJID: XMPPJID) {
		self.xmppMUCLight?.discoverRooms(forServiceNamed: MUCLightServiceName)
	}
}

extension MainViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(_ roomName: String, users: [XMPPJID]?) {
		self.newRoomUsers = users ?? []
		
		let jid = XMPPJID.init(string: MUCLightServiceName)
		let roomLight = XMPPCustomRoomLight(jid: jid!, roomname: roomName)
		roomLight.addDelegate(self, delegateQueue: DispatchQueue.main)
		
		MIMCommonInterface.createRoomWithSubject(roomLight, name: roomName, subject: "", users: self.newRoomUsers) //users will not used  here in the xmpp version of this method.
		
		_ = self.navigationController?.popViewController(animated: true)
		
	}
}
// FIXME: create room
extension MainViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(_ sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
		sender.addUsers(self.newRoomUsers)
		
		self.xmppMUCLight.discoverRooms(forServiceNamed: MUCLightServiceName)
		self.tableView.reloadData()
	}
}


