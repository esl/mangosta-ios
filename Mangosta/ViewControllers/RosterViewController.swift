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

class RosterViewController: UIViewController, TitleViewModifiable {
	@IBOutlet internal var tableView: UITableView!
	var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
	
	weak var xmppController: XMPPController!
	
	#if MangostaREST // TODO: probably better way.
	weak var mongooseRESTController : MongooseAPI!
	#endif
	
	let MIMCommonInterface = MIMMainInterface()
	
	
	var localDataSource = NSMutableArray()
    
    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String? = ""
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.xmppController = XMPPController.sharedInstance
        
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addRoster(_:)))
        self.navigationItem.rightBarButtonItems = [addButton]
        
        self.setupDataSources()
        
        self.xmppController.xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.xmppController.xmppStream.isAuthenticated() {
            self.resetTitleViewTextToOriginal()
            
        }
        else {
            let titleLabel = UILabel()
            titleLabel.text = "Connecting"
            self.navigationItem.titleView = titleLabel
            titleLabel.sizeToFit()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        try! self.fetchedResultsController?.performFetch()
        super.viewDidAppear(animated)
        
    }
	
	func addRoster(_ sender: UIBarButtonItem) {
		let alertController = UIAlertController.textFieldAlertController("Add Friend", message: "Enter the JID of the user") { (jidString) in
			guard let userJIDString = jidString, let userJID = XMPPJID.withString(userJIDString) else { return }
			self.xmppController.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.present(alertController, animated: true, completion: nil)
	}
	
	func removeRoster(_ userJID: XMPPJID) {
		self.xmppController.xmppRoster.removeUser(userJID) // TODO: revise callback
	}

	
	func createNewFriendChat(_ sender: UIBarButtonItem) {
		let alertController = UIAlertController.textFieldAlertController("New Conversation", message: "Enter the JID of the user or group name") { (jidString) in
			guard let userJIDString = jidString, let userJID = XMPPJID.withString(userJIDString) else { return }
			self.xmppController.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.present(alertController, animated: true, completion: nil)
	}
	func editTable(_ sender: UIBarButtonItem) {
		
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
		
	}
}

extension RosterViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		if let sections = self.fetchedResultsController?.sections {
			return sections.count
		}
		return 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sections = self.fetchedResultsController?.sections
		if section < sections!.count {
			let sectionInfo = sections![section]
			return sectionInfo.numberOfObjects
		}
		return 0
	}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell!
        
        if let user = self.fetchedResultsController?.object(at: indexPath) as? XMPPUserCoreDataStorageObject {
            
            if let firstResource = user.resources.first  as? XMPPResourceCoreDataStorageObject {
                if let pres = firstResource.value(forKey: "presence") {
                   // print("*FirstResource presence \(pres.type as String)")
                    if (pres as AnyObject).type == "available" {
                        cell?.imageView?.image = UIImage(named: "connected")
                    } else if (pres as AnyObject).type == "unsubscribed" {
                        print("User \(user.jid) has deleted us.")
                        self.xmppController.xmppRoster.removeUser(user.jid)
                    } else if (pres as AnyObject).type == "subscribed" {
                        // FIXME: The user accepted us. We sould have a way to dismiss this, which last until the next relog or when other we receive presence from other user than this one. :(
                        print("User \(user.jid) accepted us.")
                        if self.isAnyUserResourceAvailable(user) {
                            print("User \(user.jid) is online. ")
                            cell?.imageView?.image = UIImage(named: "connected")
                        } else {
                            print("User \(user.jid) is offline. ")
                            cell?.imageView?.image = UIImage(named: "disconnected")
                        }
                        
                    } else {
                        print("Unprocesed presence type: \((pres as AnyObject).type as String)")
                    }
                }
                
            } else { // no presence information
                if (user.subscription != nil || user.subscription == "none") && user.ask != nil {
                    if user.ask == "subscribe" {
                        cell?.imageView?.image = UIImage(named: "questionMark")
                    }
                }
                else {
                    cell?.imageView?.image = UIImage(named: "disconnected")
                }
            }
            
            cell?.textLabel?.text = user.jidStr
        } else {
            cell?.textLabel?.text = "No users"
        }
        
        cell?.textLabel?.textColor = UIColor.darkGray
        return cell!
    }
    
    func isAnyUserResourceAvailable(_ user: XMPPUserCoreDataStorageObject) -> Bool {
        if user.allResources().count > 1 {
            for r in user.allResources() {
                if let r1 = r as? XMPPResourceCoreDataStorageObject {
                    if r1.presence.type() == "available" {
                        
                       return true
                    }
                }
            }
        }
        return false
    }

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.section == 0 else { return }
		
		let useThisIndexPath = IndexPath(row: indexPath.row, section: 0)
		let user = self.fetchedResultsController?.object(at: useThisIndexPath) as! XMPPUserCoreDataStorageObject
		
		self.removeRoster(user.jid)
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
		let privateChatsIndexPath = IndexPath(row: indexPath.row, section: 0)
		let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { (UITableViewRowAction, NSIndexPath) in
			
			let rosterContext = self.xmppController.managedObjectContext_roster()
			
			if let user = self.fetchedResultsController?.object(at: privateChatsIndexPath) as? XMPPUserCoreDataStorageObject {
				self.removeRoster(user.jid)
			}
			
			do {
				try rosterContext.save()
			} catch {
				print("Error saving roster context: \(error)")
			}
		}
		
		delete.backgroundColor = UIColor.red
		leaveArray.append(delete)
		
		return leaveArray
	}

	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

}

extension RosterViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		self.tableView.reloadData()
	}
}

extension RosterViewController: XMPPRosterDelegate {
    func xmppRoster(_ sender: XMPPRoster!, didReceiveRosterPush iq: XMPPIQ!) {
        // print("iq: \(iq)")
    }
}

