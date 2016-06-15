//
//  ChatViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD

class ChatViewController: UIViewController {
	@IBOutlet internal var tableView: UITableView!
	@IBOutlet internal var buttonHeight: NSLayoutConstraint!
	@IBOutlet weak var subject: UILabel!
	@IBOutlet weak var subjectHeight: NSLayoutConstraint!

	var room: XMPPRoom?
	var roomLight: XMPPRoomLight?
	var userJID: XMPPJID?
	var fetchedResultsController: NSFetchedResultsController!
	var lastID = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		var rightBarButtonItems: [UIBarButtonItem] = []
		rightBarButtonItems.append(UIBarButtonItem(title: "Chat", style: UIBarButtonItemStyle.Done, target: self, action: #selector(showChatAlert(_:))))
		
		
		if let roomSubject = (userJID?.user ?? self.room?.roomSubject ?? self.roomLight?.roomname) {
			self.title = "Chatting with \(roomSubject)"
		}

		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showChangeSubject(_:)))
		self.subject.addGestureRecognizer(tapGesture)
		
		if self.userJID != nil {
			self.fetchedResultsController = self.createFetchedResultsController()
			self.buttonHeight.constant = 0
			self.subjectHeight.constant = 0
		} else {
			if let rLight = self.roomLight {
				rLight.addDelegate(self, delegateQueue: dispatch_get_main_queue())
				rLight.getConfiguration()
			}else {
				self.subjectHeight.constant = 0	
			}

			rightBarButtonItems.append(UIBarButtonItem(title: "Invite", style: UIBarButtonItemStyle.Done, target: self, action: #selector(invite(_:))))
			self.fetchedResultsController = self.createFetchedResultsControllerForGroup()
		}

		self.navigationItem.rightBarButtonItems = rightBarButtonItems
	}
	
	internal func showChangeSubject(sender: AnyObject?) {
		let alertController = UIAlertController(title: "Subject", message: nil, preferredStyle: UIAlertControllerStyle.Alert)

		alertController.addTextFieldWithConfigurationHandler(nil)
		alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
			if let text = alertController.textFields?.first?.text {
				self.roomLight?.changeRoomSubject(text)
			}
		}))
		alertController.view.setNeedsLayout()
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	private func createFetchedResultsControllerForGroup() -> NSFetchedResultsController {
		if let streamController = StreamManager.manager.streamController, let context = streamController.mucStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPRoomMessageCoreDataStorageObject", inManagedObjectContext: context)
			
			let roomJID = (self.room?.roomJID.bare() ?? self.roomLight?.roomJID.bare())!
			
			let predicate = NSPredicate(format: "roomJIDStr = %@", roomJID)
			let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: false)
			
			let request = NSFetchRequest()
			request.entity = entity
			request.predicate = predicate
			request.sortDescriptors = [sortDescriptor]
			
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			controller.delegate = self
			try! controller.performFetch()
			
			return controller
		}
		return NSFetchedResultsController()
	}
	
	private func createFetchedResultsController() -> NSFetchedResultsController {
		if let streamController = StreamManager.manager.streamController, let context = streamController.messageArchivingStorage.mainThreadManagedObjectContext {
			let entity = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: context)
			let predicate = NSPredicate(format: "bareJidStr = %@", self.userJID!.bare())
			let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
			
			let request = NSFetchRequest()
			request.entity = entity
			request.predicate = predicate
			request.sortDescriptors = [sortDescriptor]
			
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			controller.delegate = self
			try! controller.performFetch()
			
			return controller
		}
		return NSFetchedResultsController()
	}
	
	internal func showChatAlert(sender: AnyObject?) {
		var message = "Yo! " + "\(self.tableView.numberOfRowsInSection(0))"
		let alertController = UIAlertController(title: "Warning!", message: "It will send \(message) by default. Continue?", preferredStyle: UIAlertControllerStyle.Alert)
		
		
		alertController.addTextFieldWithConfigurationHandler(nil)
		alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
			alertController.dismissViewControllerAnimated(true, completion: nil)
		}))
		
		alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
			
			if let messageText = alertController.textFields?.first?.text where messageText.characters.count > 0 {
				message = messageText
			}

			let receiverJID = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
			let type = self.userJID != nil ? "chat" : "groupchat"
			let msg = XMPPMessage(type: type, to: receiverJID, elementID: NSUUID().UUIDString)
			msg.addBody(message)
			
			StreamManager.manager.stream.sendElement(msg)
		}))
		alertController.view.setNeedsLayout()
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	internal func invite(sender: AnyObject?) {
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
			
			if self.roomLight != nil {
				StreamManager.manager.addOperation(XMPPRoomLightOperation.invite(room: self.roomLight!, userJIDs: [userJID], completion: { (result) in
					print("Success!")
				}))
			} else {
				StreamManager.manager.addOperation(XMPPRoomOperation.invite(room: self.room!, userJIDs: [userJID], completion: { (result, room) in
					print("Success!")
				}))
			}
		}))
		alertController.view.setNeedsLayout()
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	@IBAction func showMUCDetails(sender: AnyObject) {

		if self.roomLight != nil {
			let fetchMUCLightMemberList = XMPPRoomLightOperation.fetchMembersList(room: self.roomLight!, completion: { (result, members) in
				if let membersToShow = members {
					self.showMembersViewController(membersToShow)
				}
			})
			StreamManager.manager.addOperation(fetchMUCLightMemberList)
		} else {
			let fetchMemberListOperation = XMPPRoomOperation.queryRoomItems(self.room!, completion: { (result, members) in
				if let membersToShow = members {
					self.showMembersViewController(membersToShow)
				}
			})
			StreamManager.manager.addOperation(fetchMemberListOperation)
		}
	}
	
	func showMembersViewController(members: [(String, String)]){
		let storyboard = UIStoryboard(name: "Members", bundle: nil)
		
		let membersNavController = storyboard.instantiateViewControllerWithIdentifier("members") as! UINavigationController
		let membersController = membersNavController.viewControllers.first! as! MembersViewController
		membersController.members = members
		self.navigationController?.presentViewController(membersNavController, animated: true, completion: nil)
	}
	
	@IBAction func fetchFormFields(sender: AnyObject) {
		let stream = StreamManager.manager.stream
		let mamOperation = MAMOperation.retrieveForms(stream) { (result, forms) in
			
			let formString = forms.map({ (ff) -> String in
				return "\(ff.0) \(ff.1)"
			}).joinWithSeparator("\n")
			
			let alertController = UIAlertController(title: "Forms", message: formString, preferredStyle: UIAlertControllerStyle.Alert)
			alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
			self.presentViewController(alertController, animated: true, completion: nil)
		}
		StreamManager.manager.addOperation(mamOperation)
	}

	@IBAction func fetchHistory(sender: AnyObject) {
		let stream = StreamManager.manager.stream
		let jid = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
		let mamOperation = MAMOperation.retrieveHistory(stream, jid: jid!, pageSize: 5, lastID: self.lastID) { (result, lastID) in
			if let lID = lastID {
				self.lastID = lID
			}
		}
		StreamManager.manager.addOperation(mamOperation)
	}
}

extension ChatViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(sender: XMPPRoomLight, configurationChanged message: XMPPMessage) {
		if let subject = message.elementForName("x")?.elementForName("subject")?.stringValue() {
			self.subject.text = subject
		}
	}
	
	func xmppRoomLight(sender: XMPPRoomLight, didGetConfiguration iqResult: XMPPIQ) {
		if let subject = iqResult.elementForName("query")?.elementForName("subject")?.stringValue() {
			self.subject.text = subject
		}
	}
}

extension ChatViewController: NSFetchedResultsControllerDelegate {
	//MARK: NSFetchedResultsControllerDelegate
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		self.tableView.reloadData()
	}
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
	//MARK: UITableViewDataSource, UITableViewDelegate
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
		
		if userJID != nil {
			let message = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPMessageArchiving_Message_CoreDataObject
			cell.backgroundColor = message.isOutgoing ? UIColor.lightGrayColor() : UIColor.whiteColor()
			cell.textLabel?.text = message.body
			return cell
		}
		
		let message = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! XMPPRoomMessageCoreDataStorageObject
		cell.backgroundColor = message.isFromMe ? UIColor.lightGrayColor() : UIColor.whiteColor()
		cell.textLabel?.text = message.body
		return cell
	}
}
