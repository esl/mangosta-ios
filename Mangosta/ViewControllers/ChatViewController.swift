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

	weak var room: XMPPRoom?
	weak var roomLight: XMPPRoomLight?
	var userJID: XMPPJID?
	var fetchedResultsController: NSFetchedResultsController!
	weak var xmppController: XMPPController!
	var lastID = ""
	
	let MIMCommonInterface = MIMMainInterface()
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		var rightBarButtonItems: [UIBarButtonItem] = []
		rightBarButtonItems.append(UIBarButtonItem(title: "Chat", style: UIBarButtonItemStyle.Done, target: self, action: #selector(showChatAlert(_:))))
		
		self.xmppController.xmppMessageArchiveManagement.addDelegate(self, delegateQueue: dispatch_get_main_queue())
		
		if let roomSubject = (userJID?.user ?? self.room?.roomSubject ?? self.roomLight?.roomname()) {
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
				self.room?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
				self.subjectHeight.constant = 0	
			}

			rightBarButtonItems.append(UIBarButtonItem(title: "Invite", style: UIBarButtonItemStyle.Done, target: self, action: #selector(invite(_:))))
			self.fetchedResultsController = self.createFetchedResultsControllerForGroup()
		}

		self.navigationItem.rightBarButtonItems = rightBarButtonItems
	}
	
	internal func showChangeSubject(sender: AnyObject?) {
		let alertController = UIAlertController.textFieldAlertController("Subject", message: nil) { (subjectText) in
			if let text = subjectText {
				self.roomLight?.changeRoomSubject(text)
			}
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	private func createFetchedResultsControllerForGroup() -> NSFetchedResultsController {
		let groupContext: NSManagedObjectContext!
		let entity: NSEntityDescription?
		
		if self.room != nil {
			groupContext = self.xmppController.xmppMUCStorage.mainThreadManagedObjectContext
			entity = NSEntityDescription.entityForName("XMPPRoomMessageCoreDataStorageObject", inManagedObjectContext: groupContext)
		} else {
			groupContext = self.xmppController.xmppRoomLightCoreDataStorage.mainThreadManagedObjectContext
			entity = NSEntityDescription.entityForName("XMPPRoomLightMessageCoreDataStorageObject", inManagedObjectContext: groupContext)
		}

		let roomJID = (self.room?.roomJID.bare() ?? self.roomLight?.roomJID.bare())!

		let predicate = NSPredicate(format: "roomJIDStr = %@", roomJID)
		let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: true)

		let request = NSFetchRequest()
		request.entity = entity
		request.predicate = predicate
		request.sortDescriptors = [sortDescriptor]

		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: groupContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self
		try! controller.performFetch()
		
		return controller
	}
	
	private func createFetchedResultsController() -> NSFetchedResultsController {
		guard let messageContext = self.xmppController.xmppMessageArchivingStorage.mainThreadManagedObjectContext else {
			return NSFetchedResultsController()
		}
		
		let entity = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: messageContext)
		let predicate = NSPredicate(format: "bareJidStr = %@", self.userJID!.bare())
		let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
		
		let request = NSFetchRequest()
		request.entity = entity
		request.predicate = predicate
		request.sortDescriptors = [sortDescriptor]
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: messageContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self
		try! controller.performFetch()
		
		return controller
	}
	
	internal func showChatAlert(sender: AnyObject?) {
		var message = "Yo! " + "\(self.tableView.numberOfRowsInSection(0))"
		let alertController = UIAlertController.textFieldAlertController("Warning", message: "It will send \(message) by default. Continue?") { (inputMessage) in
			if let messageText = inputMessage where messageText.characters.count > 0 {
				message = messageText
			}

			let receiverJID = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
			let type = self.userJID != nil ? "chat" : "groupchat"
			let msg = XMPPMessage(type: type, to: receiverJID, elementID: NSUUID().UUIDString)
			msg.addBody(message)
			if type == "chat" {
				self.MIMCommonInterface.sendMessage(msg)
			}
			else {
				// TODO:
				// self.MIMCommonInterface.sendMessageToRoom(self.room!, message: msg)
				self.xmppController.xmppStream.sendElement(msg) 
			}
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	internal func invite(sender: AnyObject?) {
		let alertController = UIAlertController.textFieldAlertController("Add Friend", message: "Enter the JID") { (jidString) in
			guard let userJIDString = jidString, userJID = XMPPJID.jidWithString(userJIDString) else { return }

			if self.roomLight != nil {
				self.roomLight!.addUsers([userJID])
			} else {
				self.room!.inviteUser(userJID, withMessage: self.room!.roomSubject)
			}
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	@IBAction func showMUCDetails(sender: AnyObject) {

		if self.roomLight != nil {
			self.roomLight!.fetchMembersList()
		} else {
			self.room!.queryRoomItems()
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
		self.xmppController.xmppMessageArchiveManagement.retrieveFormFields()
	}

	@IBAction func fetchHistory(sender: AnyObject) {
		let jid = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
		let fields = [XMPPMessageArchiveManagement.fieldWithVar("with", type: nil, andValue: jid!.bare())]
		let resultSet = XMPPResultSet(max: 5, after: self.lastID)
		#if MangostaREST
			// FIXME: DEBUG before vs. after
			// MIMCommonInterface.getMessagesWithUser(jid!, limit: resultSet.max(), before: 0)
			MIMCommonInterface.getMessagesWithUser(jid!, limit: nil, before: nil)
		#else
		self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
		#endif
	}

	deinit {
		self.room?.removeDelegate(self)
		self.roomLight?.removeDelegate(self)
	}
}

extension ChatViewController: XMPPRoomLightDelegate {
	
	func xmppRoomLight(sender: XMPPRoomLight, didFetchMembersList items: [DDXMLElement]) {
		let members = items.map { (child) -> (String, String) in
			return (child.attributeForName("affiliation").stringValue(), child.stringValue())
		}
		self.showMembersViewController(members)
	}

	func xmppRoomLight(sender: XMPPRoomLight, configurationChanged message: XMPPMessage) {
		self.subject.text = sender.subject()
	}

	func xmppRoomLight(sender: XMPPRoomLight, didGetConfiguration iqResult: XMPPIQ) {
		self.subject.text = sender.subject()
	}
}

extension ChatViewController: XMPPRoomExtraActionsDelegate {
	func xmppRoom(sender: XMPPRoom!, didQueryRoomItems iqResult: XMPPIQ!) {
		let members = iqResult.elementForName("query").children().map { (child) -> (String, String) in
			let ch = child as! DDXMLElement
			return (ch.attributeForName("jid").stringValue(), ch.attributeForName("name").stringValue())
		}
		self.showMembersViewController(members)
	}
}

extension ChatViewController: NSFetchedResultsControllerDelegate {
	//MARK: NSFetchedResultsControllerDelegate
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		self.tableView.reloadData()
	}
}

extension ChatViewController: XMPPMessageArchiveManagementDelegate {
	
	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessagesWithSet resultSet: XMPPResultSet!) {
		if let lastID = resultSet.elementForName("last")?.stringValue() {
			self.lastID = lastID
		}
	}

	func xmppMessageArchiveManagement(xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveFormFields iq: XMPPIQ!) {
		let fields = iq.childElement().elementForName("x").elementsForName("field").map { (field) -> String in
			let f = field as! NSXMLElement
			return "\(f.attributeForName("var").stringValue()!) \(f.attributeForName("type").stringValue()!)"
		}.joinWithSeparator("\n")
		
		let alertController = UIAlertController(title: "Forms", message: fields, preferredStyle: UIAlertControllerStyle.Alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
		self.presentViewController(alertController, animated: true, completion: nil)
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
