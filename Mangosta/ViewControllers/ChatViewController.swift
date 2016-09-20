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
	var lastSentMessageID = ""

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
	private func getCurrentContextAndEntityDescription() -> (NSManagedObjectContext, NSEntityDescription?) {
		let groupContext: NSManagedObjectContext!
		let entity: NSEntityDescription?
		
		if self.room != nil {
			groupContext = self.xmppController.xmppMUCStorage.mainThreadManagedObjectContext
			entity = NSEntityDescription.entityForName("XMPPRoomMessageCoreDataStorageObject", inManagedObjectContext: groupContext)
		} else {
			groupContext = self.xmppController.xmppRoomLightCoreDataStorage.mainThreadManagedObjectContext
			entity = NSEntityDescription.entityForName("XMPPRoomLightMessageCoreDataStorageObject", inManagedObjectContext: groupContext)
		}
		return (groupContext, entity)
	}
	private func createFetchedResultsControllerForGroup() -> NSFetchedResultsController {

		let (groupContext, entity) = self.getCurrentContextAndEntityDescription()
		
		let roomJID = (self.room?.roomJID.bare() ?? self.roomLight?.roomJID.bare())!

		let predicate = NSPredicate(format: "roomJIDStr = %@", roomJID)
		let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: false)

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
			
			let msgUUID = NSUUID().UUIDString
			let msg = XMPPMessage(type: type, to: receiverJID, elementID: msgUUID )
			msg.addBody(message)

			self.xmppController.xmppStream.sendElement(msg)
			
			self.lastSentMessageID = msgUUID
		}
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	internal func isLastMessageCorrectionEnabled() -> Bool {
		return true
	}
	
	internal func isPartnerClientSupportingLastMessageCorrection(partnerJID: XMPPJID) -> Bool {
		return true
	}
	
	internal func sendLastMessageCorrection(messageID: String, replacingEntityMessage: AnyObject) {
		// TODO: Find out if the XEP is active on the server plus the other side client supports this.
		// TODO: Fix XMPPFramework support for XEP-0308
		var message = "this is the corrected message " + "\(self.tableView.numberOfRowsInSection(0))"
		let alertController = UIAlertController.textFieldAlertController("Warning", message: "It will send \(message) by default. Continue?") { (inputMessage) in
			if let messageText = inputMessage where messageText.characters.count > 0 {
				message = messageText
			}
			
			let receiverJID = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
			let type = self.userJID != nil ? "chat" : "groupchat"
			
			let msg = XMPPMessage(type: type, to: receiverJID, elementID: NSUUID().UUIDString)
			
			if let correctionMessage = self.addMessageCorrectionWithIDLocal(self.lastSentMessageID) {
				msg.addBody(message)
				msg.addChild(correctionMessage)
				
				self.replaceInLocalStorage(msg)
				self.xmppController.xmppStream.sendElement(msg)
			}
			else {
				print("No correction message was generated")
			}
		}
		if self.lastSentMessageID != "" {
			self.presentViewController(alertController, animated: true, completion: nil)
		}
	}
	
	
	
	func replaceInLocalStorage(message: XMPPMessage) {
		
		let e = message.elementForName("replace")
		let replaceId = e.attributeForName("id")
		
		let (moc, _) = self.getCurrentContextAndEntityDescription()
		
		let predicateFormat = "    fromMe == %@ "
		let predicate = NSPredicate(format: predicateFormat, true)
		let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: true)
		let sortDescriptors = [sortDescriptor]
		let fetchRequest = NSFetchRequest()
		
		fetchRequest.entity = NSEntityDescription.entityForName("XMPPRoomMessageCoreDataStorageObject", inManagedObjectContext: moc )
		fetchRequest.predicate = predicate
		fetchRequest.sortDescriptors = sortDescriptors
		
		let error: NSError? = nil
		let results = try! moc.executeFetchRequest(fetchRequest)
		if results.isEmpty {
			print("Error fetching entity objects: \(error!.localizedDescription)\n\(error!.userInfo)")
			abort()
		}
		else {
			var done = false
			for o: Any in results {
				// TODO: extend this to MUC light using isKindOfClass
				let thisMessageEntity = (o as! XMPPRoomMessageCoreDataStorageObject)
				let thisMessage = thisMessageEntity.message
				let thisMessageId = thisMessage.attributeForName("id")
				if replaceId.stringValue() == thisMessageId.stringValue() {
					print("Id to replace is: \(thisMessageId.stringValue())")
					thisMessageEntity.message = message
					thisMessageEntity.body = message.body()
					// thisMessageEntity.localTimestamp = localTimestamp
					moc.refreshObject(thisMessageEntity, mergeChanges: false)
					do {
						try moc.save()
					} catch {
						fatalError("Failure to save context: \(error)")
					}
					
					tableView.reloadData()
					done = true
					break
				}
			}
			if !done {
				print("Replacement ID # \(replaceId) not found.")
			}
		}
	}

	func fetchHistoryForCorrectionWithID(message: XMPPMessage) {
		let fields = [XMPPMessageArchiveManagement.fieldWithVar("id", type: nil, andValue: message.elementForName("replace").attributeForName("id").stringValue())]
		let resultSet = XMPPResultSet(max: 1, after: self.lastID)
		self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
	}
	
	internal func addMessageCorrectionWithIDLocal(messageCorrectionID: String) -> DDXMLElement?{
		let replace = NSXMLElement.elementWithName("replace") as? DDXMLElement
		replace!.addAttributeWithName("id", stringValue: messageCorrectionID)
		replace!.addAttributeWithName("xmlns", stringValue: "urn:xmpp:message-correct:0")
		return replace
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
		self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchiveWithFields(fields, withResultSet: resultSet)
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
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let indexPath = tableView.indexPathForSelectedRow!
		// TODO: extend this to P2P and MucLight using isKindOfClass
		if let messageEntity = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? XMPPRoomMessageCoreDataStorageObject {
			if messageEntity.isFromMe || (messageEntity.streamBareJidStr != nil && messageEntity.streamBareJidStr == xmppController.xmppStream.myJID.bare()) { // message is either group chat or P2P and from me
				// Only allow selection on a cell that holds the last message only
				if messageEntity.message.attributeForName("id").stringValue() == self.lastSentMessageID {
					self.sendLastMessageCorrection(self.lastSentMessageID, replacingEntityMessage: messageEntity)
				}
			}
		}
	}
	func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
		if (indexPath.row != 0) { // TODO: invert this question to the last row after merging PR#13
			return nil
		}
		return indexPath
	}
}
