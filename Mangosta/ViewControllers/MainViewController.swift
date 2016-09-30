
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
	var activated = true
	weak var xmppController: XMPPController!
	
	#if MangostaREST // TODO: probably better way.
	weak var mongooseRESTController : MongooseAPI!
	#endif
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Roster"

		let addFriendButton = UIBarButtonItem(title: "Add Friend", style: UIBarButtonItemStyle.Done, target: self, action: #selector(addFriend(_:)))
		self.navigationItem.rightBarButtonItem = addFriendButton
		
		let logOut = UIBarButtonItem(title: "Log Out", style: UIBarButtonItemStyle.Done, target: self, action: #selector(logOut(_:)))
		self.navigationItem.leftBarButtonItem = logOut
		
		if AuthenticationModel.load() == nil {
			presentLogInView()
		} else {
			configureAndStartXMPP()
		}
	}
	
	func presentLogInView() {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
		let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		loginController.loginDelegate = self
		self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
	}
	
	func configureAndStartXMPP() {

		let authModel = AuthenticationModel.load()!

		self.xmppController = XMPPController(hostName: authModel.serverName!,
		                                     userJID: authModel.jid,
		                                     password: authModel.password)
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		appDelegate.xmppController = self.xmppController
		
		xmppController.connect()
		self.setupFetchedResultsController()
		
		#if MangostaREST
			self.mongooseRESTController = MongooseAPI()
			appDelegate.mongooseRESTController = self.mongooseRESTController
		#endif
	}
	
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
	
	func logOut(sender: UIBarButtonItem){
		AuthenticationModel.remove()
		self.presentLogInView()
		self.xmppController.disconnect()
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		appDelegate.xmppController = nil
		self.xmppController = nil
		#if MangostaREST
			appDelegate.mongooseRESTController = nil
			self.mongooseRESTController = nil
		#endif
		
	}
	
	func addFriend(sender: UIBarButtonItem){
		let alertController = UIAlertController.textFieldAlertController("Add Friend", message: "Enter the JID of the user") { (jidString) in
			guard let userJIDString = jidString, userJID = XMPPJID.jidWithString(userJIDString) else { return }
			self.xmppController.xmppRoster.addUser(userJID, withNickname: nil)
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	internal func setupFetchedResultsController() {

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
		chatController.xmppController = self.xmppController
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
		self.configureAndStartXMPP() // and MongooseREST API
	}
}

