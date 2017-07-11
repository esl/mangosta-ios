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
        
        let rightBarButtonItems = [UIBarButtonItem(title: "Actions", style: .plain, target: self, action: #selector(additionalActionsBarButtonItemTapped(_:)))]
        for barButtonItem in rightBarButtonItems {
            barButtonItem.tintColor = .mangostaDarkGreen
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems

        // FIXME: not complete solution
        self.navigationController?.navigationBar.barTintColor = .mangostaVeryLightGreen

        MangostaSettings().setNavigationBarColor()

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
        let baseMessageStyle = BaseMessageCollectionViewCellDefaultStyle(colors: BaseMessageCollectionViewCellDefaultStyle.Colors(incoming: .mangostaVeryLightGreen, outgoing: .mangostaDarkGreen))
        textMessagePresenter.baseMessageStyle = baseMessageStyle
        textMessagePresenter.textCellStyle = TextMessageCollectionViewCellDefaultStyle(baseStyle: baseMessageStyle)

        let photoMessagePresenter = PhotoMessagePresenterBuilder(
            viewModelBuilder: TransferAwarePhotoMessageViewModelDefaultBuilder(),
            interactionHandler: XMPPMessageInteractionHandler<PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>>()
        )
        photoMessagePresenter.baseCellStyle = baseMessageStyle
        
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
    
    @IBAction func additionalActionsBarButtonItemTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for additionalAction in additionalActions {
            actionSheet.addAction(UIAlertAction(title: additionalAction.label, style: .default) { _ in
                additionalAction.perform(inContextOf: self)
            })
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
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
