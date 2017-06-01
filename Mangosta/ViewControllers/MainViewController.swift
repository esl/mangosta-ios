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
	weak var xmppController: XMPPController!
	
	let sections = ["Group chats", "Private chats"]
	
    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String? = "Chats"
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }
    
	override func viewDidLoad() {
        
        self.xmppController = XMPPController.sharedInstance
        self.xmppController.roomListDelegate = self
        
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
        
        if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowIndexPath, animated: animated)
        }
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        try! self.fetchedResultsController?.performFetch()
        super.viewDidAppear(animated)
    }
	
	func presentLogInView() {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
		let loginController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController

		self.navigationController?.present(loginController, animated: true, completion: nil)
	}
    
    func switchToPrivateChat(with user: XMPPUser, userInitiated isUserInitiated: Bool) {
        if !isUserInitiated, let chatIndex = (fetchedResultsController?.fetchedObjects?.index { $0 === user }) {
            tableView.selectRow(at: IndexPath(row: chatIndex, section: 1), animated: false, scrollPosition: .none)
        }
        
        let chatViewController = ChatViewController(
            modifiableTitle: user.jid().user,
            chatDataSource: XMPPCoreDataChatDataSource(
                messageArchivingManagedObjectContext: xmppController.xmppMessageArchivingStorage.mainThreadManagedObjectContext,
                userJid: user.jid().bare(),
                messageContentFilters: [xmppController.xmppRoster]
            ),
            messageSender: xmppController.xmppOneToOneChat.session(forUserJID: user.jid().bare()),
            additionalActions: [XMPPOneToOneChatMessageHistoryFetchAction(xmppController: xmppController, userJid: user.jid().bare())]
        )
        
        switchToChat(with: chatViewController, animated: isUserInitiated)
    }
    
    func switchToGroupChat(in room: XMPPRoomLight, userInitiated isUserInitiated: Bool) {
        if !isUserInitiated, let roomIndex = xmppController.roomsLight.index(of: room) {
            tableView.selectRow(at: IndexPath(row: roomIndex, section: 0), animated: false, scrollPosition: .none)
        }
        
        let chatViewController = ChatViewController(
            modifiableTitle: room.roomname(),
            chatDataSource: XMPPCoreDataChatDataSource(
                roomStorageManagedObjectContext: xmppController.xmppRoomLightCoreDataStorage.mainThreadManagedObjectContext,
                roomJid: room.roomJID,
                messageContentFilters: [xmppController.xmppRoster]
            ),
            messageSender: room,
            additionalActions: [
                XMPPRoomChatMessageHistoryFetchAction(xmppController: xmppController, roomJid: room.roomJID),
                XMPPRoomMemberInviteAction(room: room)
            ]
        )
        
        switchToChat(with: chatViewController, animated: isUserInitiated)
    }
    
    func switchToChat(with chatViewController: ChatViewController, animated: Bool) {
        _ = self.navigationController?.popToViewController(self, animated: false)
        navigationController?.pushViewController(chatViewController, animated: animated)
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
			let roomCreatePresenterViewController = storyboard.instantiateViewController(withIdentifier: "MUCLightCreateRoomPresenterViewController") as! UINavigationController
            let roomCreateViewController = roomCreatePresenterViewController.topViewController as! MUCRoomCreateViewController
            roomCreateViewController.delegate = self
			self.present(roomCreatePresenterViewController, animated: true, completion: nil)
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
        switch indexPath.section {
        case 0:
            switchToGroupChat(in: xmppController.roomsLight[indexPath.row], userInitiated: true)
        case 1:
            switchToPrivateChat(with: fetchedResultsController!.fetchedObjects![indexPath.row] as! XMPPUser, userInitiated: true)
        default:
            break
        }
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
                let user = self.fetchedResultsController?.object(at: privateChatsIndexPath) as! XMPPUser
				self.xmppController.xmppRoster.removeUser(user.jid())
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

extension MainViewController: XMPPControllerRoomListDelegate {
    
    func roomListDidChange(in controller: XMPPController) {
        OperationQueue.main.addOperation {
            self.tableView.reloadData()
        }
    }
}

extension MainViewController: MUCRoomCreateViewControllerDelegate {
	
	func createRoom(_ roomName: String, users: [XMPPJID]?) {
		xmppController.addRoom(withName: roomName, initialOccupantJids: users)
        dismiss(animated: true, completion: nil)
	}
}
