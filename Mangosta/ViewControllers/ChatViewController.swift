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
import Chatto
import ChattoAdditions

class ChatViewController: BaseChatViewController, UIGestureRecognizerDelegate, TitleViewModifiable {
	@IBOutlet weak var subject: UILabel!
	@IBOutlet weak var subjectHeight: NSLayoutConstraint!
    
	weak var room: XMPPRoom?
	weak var roomLight: XMPPRoomLight?
	var userJID: XMPPJID?
	var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
	weak var xmppController: XMPPController!
	var lastID = ""

	let MIMCommonInterface = MIMMainInterface()

    public private(set) var wallpaperView: UIImageView!
    
    var messageSender: QueueMessageSender!
    var dataSource: QueueDataSource! {
        didSet {
            self.chatDataSource = self.dataSource
        }
    }
    
    lazy private var baseMessageHandler: BaseMessageHandler = {
        return BaseMessageHandler(messageSender: self.messageSender)
    }()

//	let messageLayoutCache = NSCache<AnyObject, AnyObject>()  // TODO: Do we need this?

    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String?
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Note that this componet needs to have. First the datasource and it's messageSender, which was passed on MainViewController, before starting the decorator.
        self.messageSender = dataSource.messageSender
        super.chatItemsDecorator = ChatItemsDemoDecorator()
        
        self.addWallpaperView()
        
        var rightBarButtonItems: [UIBarButtonItem] = []

        wallpaperView.image = UIImage(named: "chat_background")!

        self.xmppController.xmppMessageArchiveManagement.addDelegate(self, delegateQueue: DispatchQueue.main)

        if let roomSubject = (userJID?.user ?? self.room?.roomSubject ?? self.roomLight?.roomname()) {
            self.title = "\(roomSubject)"
            self.originalTitleViewText = self.title
        }


        if self.userJID != nil {
            self.fetchedResultsController = self.createFetchedResultsController()
        } else {
            if let rLight = self.roomLight {
                rLight.addDelegate(self, delegateQueue: DispatchQueue.main)
                rLight.getConfiguration()
            }else {
                self.room?.addDelegate(self, delegateQueue: DispatchQueue.main)
                self.subjectHeight.constant = 0
            }

            rightBarButtonItems.append(UIBarButtonItem(title: "Invite", style: UIBarButtonItemStyle.done, target: self, action: #selector(invite(_:))))
            let d = rightBarButtonItems[0]
            d.tintColor = UIColor(hexString:"009ab5")

            self.fetchedResultsController = self.createFetchedResultsControllerForGroup()
        }

        self.navigationItem.rightBarButtonItems = rightBarButtonItems

        // FIXME: not complete solution
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.737, green: 0.933, blue: 0.969, alpha: 1.00)

        MangostaSettings().setNavigationBarColor()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func addWallpaperView() {
        wallpaperView = UIImageView(frame: CGRect.zero)
        wallpaperView.translatesAutoresizingMaskIntoConstraints = false
        wallpaperView.contentMode = .scaleAspectFill
        wallpaperView.clipsToBounds = true
        view.addSubview(wallpaperView)
        view.sendSubview(toBack: wallpaperView)
    }


    var chatInputPresenter: BasicChatInputBarPresenter!
    override func createChatInputView() -> UIView {
        let chatInputView = ChatInputBar.loadNib()
        var appearance = ChatInputBarAppearance()
        appearance.sendButtonAppearance.title = NSLocalizedString("Send", comment: "")
        appearance.textInputAppearance.placeholderText = NSLocalizedString("Type a message", comment: "")
        self.chatInputPresenter = BasicChatInputBarPresenter(chatInputBar: chatInputView, chatInputItems: self.createChatInputItems(), chatInputBarAppearance: appearance)
        chatInputView.maxCharactersCount = 1000
        return chatInputView
    }

    override func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        let textMessagePresenter = TextMessagePresenterBuilder(
            viewModelBuilder: DemoTextMessageViewModelBuilder(),
            interactionHandler: DemoTextMessageHandler(baseHandler: self.baseMessageHandler)
        )
        textMessagePresenter.baseMessageStyle = BaseMessageCollectionViewCellDefaultStyle()

        let photoMessagePresenter = PhotoMessagePresenterBuilder(
            viewModelBuilder: DemoPhotoMessageViewModelBuilder(),
            interactionHandler: DemoPhotoMessageHandler(baseHandler: self.baseMessageHandler)
        )
        photoMessagePresenter.baseCellStyle = BaseMessageCollectionViewCellDefaultStyle()

        return [
            DemoTextMessageModel.chatItemType: [
                textMessagePresenter
            ],
            DemoPhotoMessageModel.chatItemType: [
                photoMessagePresenter
            ],
            SendingStatusModel.chatItemType: [SendingStatusPresenterBuilder()],
            TimeSeparatorModel.chatItemType: [TimeSeparatorPresenterBuilder()]
        ]
    }
    func createChatInputItems() -> [ChatInputItemProtocol] {
        var items = [ChatInputItemProtocol]()
        items.append(self.createTextInputItem())
        items.append(self.createPhotoInputItem())
        return items
    }

    private func createTextInputItem() -> TextChatInputItem {
        let item = TextChatInputItem()
        item.textInputHandler = { [weak self] text in
            self?.dataSource.addTextMessage(text)
        }
        return item
    }

    private func createPhotoInputItem() -> PhotosChatInputItem {
        let item = PhotosChatInputItem(presentingController: self)
        item.photoInputHandler = { [weak self] image in
            self?.dataSource?.addPhotoMessage(image)
        }
        return item
    }

	override var canBecomeFirstResponder : Bool {
		return true
	}

	internal func showChangeSubject(_ sender: AnyObject?) {
		let alertController = UIAlertController.textFieldAlertController("Subject", message: nil) { (subjectText) in
			if let text = subjectText {
				self.roomLight?.changeRoomSubject(text)
			}
		}
		self.present(alertController, animated: true, completion: nil)
	}

	fileprivate func createFetchedResultsControllerForGroup() -> NSFetchedResultsController<NSFetchRequestResult> {
		let groupContext: NSManagedObjectContext!
		let entity: NSEntityDescription?

		if self.room != nil {
			groupContext = self.xmppController.xmppMUCStorage.mainThreadManagedObjectContext
			entity = NSEntityDescription.entity(forEntityName: "XMPPRoomMessageCoreDataStorageObject", in: groupContext)
		} else {
			groupContext = self.xmppController.xmppRoomLightCoreDataStorage.mainThreadManagedObjectContext
			entity = NSEntityDescription.entity(forEntityName: "XMPPRoomLightMessageCoreDataStorageObject", in: groupContext)
		}


		let roomJID = (self.room?.roomJID.bare() as String! ?? self.roomLight?.roomJID.bare() as String!) as String

		let predicate = NSPredicate(format: "roomJIDStr = %@", roomJID)
		let sortDescriptor = NSSortDescriptor(key: "localTimestamp", ascending: true)

		let request = NSFetchRequest<NSFetchRequestResult>()
		request.entity = entity
		request.predicate = predicate
		request.sortDescriptors = [sortDescriptor]

		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: groupContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self
		try! controller.performFetch()

		return controller
	}

	fileprivate func createFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
		guard let messageContext = self.xmppController.xmppMessageArchivingStorage.mainThreadManagedObjectContext else {
			return NSFetchedResultsController()
		}

		let entity = NSEntityDescription.entity(forEntityName: "XMPPMessageArchiving_Message_CoreDataObject", in: messageContext)
		let predicate = NSPredicate(format: "bareJidStr = %@", self.userJID!.bare() as String!)
		let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)

		let request = NSFetchRequest<NSFetchRequestResult>()
		request.entity = entity
		request.predicate = predicate
		request.sortDescriptors = [sortDescriptor]

		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: messageContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self
		try! controller.performFetch()

		return controller
	}

	internal func invite(_ sender: AnyObject?) {
		let alertController = UIAlertController.textFieldAlertController("Add member", message: "Enter the JID") { (jidString) in
			guard let userJIDString = jidString, let userJID = XMPPJID.init(string: userJIDString) else { return }

			if self.roomLight != nil {
				self.roomLight!.addUsers([userJID])
			} else {
				self.room!.inviteUser(userJID, withMessage: self.room!.roomSubject)
			}
		}
		self.present(alertController, animated: true, completion: nil)
	}

	@IBAction func showMUCDetails(_ sender: AnyObject) {

		if self.roomLight != nil {
			self.roomLight!.fetchMembersList()
		} else {
			self.room!.queryRoomItems()
		}
	}

	func showMembersViewController(_ members: [(String, String)]) {
		let storyboard = UIStoryboard(name: "Members", bundle: nil)

		let membersNavController = storyboard.instantiateViewController(withIdentifier: "members") as! UINavigationController
		let membersController = membersNavController.viewControllers.first! as! MembersViewController
		membersController.members = members
		self.navigationController?.present(membersNavController, animated: true, completion: nil)
	}

	@IBAction func fetchFormFields(_ sender: AnyObject) {
		self.xmppController.xmppMessageArchiveManagement.retrieveFormFields()
	}

	@IBAction func fetchHistory(_ sender: AnyObject) {
		let jid = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
		let fields = [XMPPMessageArchiveManagement.field(withVar: "with", type: nil, andValue: jid!.bare())]
		let resultSet = XMPPResultSet(max: 5, after: self.lastID)
		#if MangostaREST
			// TODO: add before and after
			_ = MIMCommonInterface.getMessagesWithUser(user: jid!, limit: nil, before: nil)
		#endif
		self.xmppController.xmppMessageArchiveManagement.retrieveMessageArchive(withFields: fields, with: resultSet)
	}

	deinit {
		self.room?.removeDelegate(self)
		self.roomLight?.removeDelegate(self)
	}
    
  
	func sendMessageToServer(_ lastMessage: DemoTextMessageModel?) {
        // TODO: make this funcion aware of picture type message
        guard let lastMessage = lastMessage else { return } 
		let receiverJID = self.userJID ?? self.room?.roomJID ?? self.roomLight?.roomJID
		let type = self.userJID != nil ? "chat" : "groupchat"
		let msg = XMPPMessage(type: type, to: receiverJID, elementID: UUID().uuidString)

		msg?.addBody(lastMessage.text)
        if let msg = msg { self.MIMCommonInterface.sendMessage(msg) }
        else { print("Error sending message: \(msg)") }
	}
}

// MARK: ChatDataSourceDelegateProtocol

extension ChatViewController: XMPPRoomLightDelegate {

	func xmppRoomLight(_ sender: XMPPRoomLight, didFetchMembersList items: [DDXMLElement]) {
		let members = items.map { (child) -> (String, String) in
			return (child.attribute(forName: "affiliation")!.stringValue!, child.stringValue!)
		}
		self.showMembersViewController(members)
	}

	func xmppRoomLight(_ sender: XMPPRoomLight, configurationChanged message: XMPPMessage) {
		self.title = sender.subject()
	}

	func xmppRoomLight(_ sender: XMPPRoomLight, didGetConfiguration iqResult: XMPPIQ) {
		self.title = sender.subject()
	}
}

extension ChatViewController: XMPPRoomExtraActionsDelegate {
	func xmppRoom(_ sender: XMPPRoom!, didQueryRoomItems iqResult: XMPPIQ!) {
		let members = iqResult.forName("query")!.children!.map { (child) -> (String, String) in
			let ch = child as! DDXMLElement
			return (ch.attribute(forName: "jid")!.stringValue!, ch.attribute(forName: "name")!.stringValue!)
		}
		self.showMembersViewController(members)
	}
}

extension ChatViewController: NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsControllerDelegate
    
    @objc(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:) func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                                                                                              didChange anObject: Any,
                                                                                              at indexPath: IndexPath?,
                                                                                              for type: NSFetchedResultsChangeType,
                                                                                              newIndexPath: IndexPath?) {
        switch anObject {
        case let privateMessage as XMPPMessageArchiving_Message_CoreDataObject where privateMessage.body != nil && !privateMessage.isOutgoing:
            let message = createTextMessageModel(privateMessage.message.chatId, text: privateMessage.body, isIncoming: true)
            self.dataSource.addIncomingTextMessage(message: message)
            
        case let roomMessage as XMPPRoomMessage where roomMessage.body() != nil && !roomMessage.isFromMe():
            let message = createTextMessageModel(roomMessage.message().chatId, text: roomMessage.body(), isIncoming: true)
            self.dataSource.addIncomingTextMessage(message: message)
        default: break
        }
    }
}

extension ChatViewController: XMPPMessageArchiveManagementDelegate {

	func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessagesWith resultSet: XMPPResultSet!) {
		if let lastID = resultSet.forName("last")?.stringValue! {
			self.lastID = lastID
		}
	}

	func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveFormFields iq: XMPPIQ!) {
		let fields = iq.childElement().forName("x")!.elements(forName: "field").map { (field) -> String in
			let f = field
			return "\(f.attribute(forName: "var")!.stringValue!) \(f.attribute(forName: "type")!.stringValue!)"
		}.joined(separator: "\n")

		let alertController = UIAlertController(title: "Forms", message: fields, preferredStyle: UIAlertControllerStyle.alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		self.present(alertController, animated: true, completion: nil)
	}
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMAMMessage message: XMPPMessage!) {
        print ("received")
    }
}

extension ChatViewController: XMPPStreamDelegate {
    func xmppStream(_ sender: XMPPStream!, didSend message: XMPPMessage!) {
        // TODO: set message status to sent
    }
}

private extension XMPPMessage {
    
    var chatId: String {
        // use the stanza id for direct messages or the resultId copied from an enclosing element for messages received via MAM
        guard let chatItemId = elementID() ?? archiveResultId else { fatalError("Cannot extract chat identifier for message: \(self)") }
        return chatItemId
    }
    
    var archiveResultId: String? {
        return attributeStringValue(forName: "resultId")
    }
}

