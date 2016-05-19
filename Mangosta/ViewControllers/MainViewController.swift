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

class MainViewController: UIViewController {
	@IBOutlet internal var tableView: UITableView!
	var fetchedResultsController: NSFetchedResultsController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Roster"
		
		let addFriendButton = UIBarButtonItem(title: "Add Friend", style: UIBarButtonItemStyle.Done, target: self, action: #selector(addFriend(_:)))
		self.navigationItem.rightBarButtonItem = addFriendButton
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.setupFetchedResultsController), name: Constants.Notifications.RosterWasUpdated, object: nil)
		
		self.startup()
	}
	
	func addFriend(sender: UIBarButtonItem){
		let alertController = UIAlertController(title: "Add Friend", message: "Enter the JID of the user.", preferredStyle: UIAlertControllerStyle.Alert)
		alertController.addTextFieldWithConfigurationHandler(nil)

		alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
			alertController.dismissViewControllerAnimated(true, completion: nil)
		}))
		
		alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
			guard let userJIDString = alertController.textFields?.first?.text where userJIDString.characters.count > 0 else {
				alertController.dismissViewControllerAnimated(true, completion: nil)
				return
			}
			// roster.addUser doesn't check if there is a roster... we have to fix this.
			let userJID = XMPPJID.jidWithString(userJIDString)!
			StreamManager.manager.streamController?.roster.addUser(userJID, withNickname: nil)
		}))
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	internal func setupFetchedResultsController() {
		if self.fetchedResultsController != nil {
			self.fetchedResultsController = nil
		}
		if let streamController = StreamManager.manager.streamController, context = streamController.rosterStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: context)
			let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
			let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
			
			let fetchRequest = NSFetchRequest()
			fetchRequest.entity = entity
			fetchRequest.sortDescriptors = [sd1, sd2]
			self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "sectionNum", cacheName: nil)
			self.fetchedResultsController?.delegate = self
			
			try! self.fetchedResultsController?.performFetch()
			self.tableView.reloadData()
		}
	}
	
	internal func logout(sender: AnyObject?) {
		StreamManager.manager.disconnect()
		AuthenticationModel.remove()
		
		self.startup()
	}
	
	internal func login(sender: AnyObject?) {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)

		let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		loginController.loginDelegate = self
		self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
	}

	private func startup() {
		var logButton: UIBarButtonItem = UIBarButtonItem()
		
		if let auth = AuthenticationModel.load() {
			let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
			hud.labelText = "Connecting..."
			
			StreamManager.manager.begin(auth.jid.bare(), password: auth.password, serverName: auth.serverName) {
				MBProgressHUD.hideHUDForView(self.view, animated: true)
			}
			
			logButton = UIBarButtonItem(title: "Log Out", style: UIBarButtonItemStyle.Done, target: self, action: #selector(logout(_:)))
		} else {
			logButton = UIBarButtonItem(title: "Log In", style: UIBarButtonItemStyle.Done, target: self, action: #selector(login(_:)))
		}
		self.navigationItem.leftBarButtonItem = logButton
		
		self.setupFetchedResultsController()
	}
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
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
		let user = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPUserCoreDataStorageObject
		let storyboard = UIStoryboard(name: "Chat", bundle: nil)

		let chatController = storyboard.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
		chatController.userJID = user.jid
		
		self.navigationController?.pushViewController(chatController, animated: true)
		
	}
}

extension MainViewController: NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.reloadData()
	}
}

extension MainViewController: LoginControllerDelegate {
	func didLogIn() {
		self.startup()
	}
}

