//
//  ChatViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import MBProgressHUD
import Chatto
import ChattoAdditions

class ChatViewController: BaseChatViewController, UIGestureRecognizerDelegate, TitleViewModifiable {
    
    let titleProvider: ChatViewControllerTitleProvider
    let messageSender: ChatViewControllerMessageSender
    let additionalActions: [ChatViewControllerAdditionalAction]
    
    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String?
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }

    init(titleProvider: ChatViewControllerTitleProvider, chatDataSource: ChatDataSourceProtocol, messageSender: ChatViewControllerMessageSender, additionalActions: [ChatViewControllerAdditionalAction]) {
        self.titleProvider = titleProvider
        self.messageSender = messageSender
        self.additionalActions = additionalActions
        super.init(nibName: nil, bundle: nil)
        
        self.chatDataSource = chatDataSource
        self.titleProvider.delegate = self
        updateTitle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        super.chatItemsDecorator = ChatItemsDemoDecorator()
        
        self.addWallpaperView()
        
        let rightBarButtonItems = additionalActions.map {
            UIBarButtonItem(title: $0.label, style: .plain, target: self, action: #selector(additionalActionBarButtonItemTapped(_:)))
        }
        for barButtonItem in rightBarButtonItems {
            barButtonItem.tintColor = UIColor(hexString:"009ab5")
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems

        // FIXME: not complete solution
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.737, green: 0.933, blue: 0.969, alpha: 1.00)

        MangostaSettings().setNavigationBarColor()

    }
    
    private func addWallpaperView() {
        let wallpaperView = UIImageView(frame: CGRect.zero)
        wallpaperView.translatesAutoresizingMaskIntoConstraints = false
        wallpaperView.contentMode = .scaleAspectFill
        wallpaperView.clipsToBounds = true
        wallpaperView.image = UIImage(named: "chat_background")
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
            viewModelBuilder: TextMessageViewModelDefaultBuilder(),
            interactionHandler: XMPPMessageInteractionHandler<TextMessageViewModel<TextMessageModel<MessageModel>>>()
        )
        textMessagePresenter.baseMessageStyle = BaseMessageCollectionViewCellDefaultStyle()

        let photoMessagePresenter = PhotoMessagePresenterBuilder(
            viewModelBuilder: PhotoMessageViewModelDefaultBuilder(),
            interactionHandler: XMPPMessageInteractionHandler<PhotoMessageViewModel<PhotoMessageModel<MessageModel>>>()
        )
        photoMessagePresenter.baseCellStyle = BaseMessageCollectionViewCellDefaultStyle()

        return [
            MessageModel.textItemType: [textMessagePresenter],
            MessageModel.photoItemType: [photoMessagePresenter],
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
    
    fileprivate func updateTitle() {
        if navigationItem.titleView == nil && navigationItem.title == originalTitleViewText {
            navigationItem.title = titleProvider.chatTitle
        }
        originalTitleViewText = titleProvider.chatTitle
    }

    private func createTextInputItem() -> TextChatInputItem {
        let item = TextChatInputItem()
        item.textInputHandler = { [weak self] text in
            guard let controller = self else { return }
            controller.messageSender.chatViewController(controller, didRequestToSendMessageWithText: text)
        }
        return item
    }

    private func createPhotoInputItem() -> PhotosChatInputItem {
        let item = PhotosChatInputItem(presentingController: self)
        item.photoInputHandler = { [weak self] image in
            guard let controller = self else { return }
            controller.messageSender.chatViewController(controller, didRequestToSendMessageWithImage: image)
        }
        return item
    }

	override var canBecomeFirstResponder : Bool {
		return true
	}
    
    @IBAction func additionalActionBarButtonItemTapped(_ sender: UIBarButtonItem) {
        guard let action = (navigationItem.rightBarButtonItems?.index(of: sender).map { additionalActions[$0] }) else {
            return
        }
        action.perform(inContextOf: self)
    }
}

protocol ChatViewControllerTitleProvider: class {
    
    var chatTitle: String { get }
    weak var delegate: ChatViewControllerTitleProviderDelegate? { get set }
}

protocol ChatViewControllerTitleProviderDelegate: class {
    
    func chatViewControllerTitleProviderDidChangeTitle(_ titleProvider: ChatViewControllerTitleProvider)
}

protocol ChatViewControllerMessageSender: class {
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithText messageText: String)
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithImage messageImage: UIImage)
}

protocol ChatViewControllerAdditionalAction {
    
    var label: String { get }
    func perform(inContextOf chatViewController: ChatViewController)
}

extension ChatViewControllerTitleProvider {
    
    weak var delegate: ChatViewControllerTitleProviderDelegate? {
        get { fatalError() } set {}
    }
}

extension ChatViewController: ChatViewControllerTitleProviderDelegate {
    
    func chatViewControllerTitleProviderDidChangeTitle(_ titleProvider: ChatViewControllerTitleProvider) {
        updateTitle()
    }
}
