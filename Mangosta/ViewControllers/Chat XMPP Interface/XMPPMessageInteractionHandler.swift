//
//  XMPPMessageInteractionHandler.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import ChattoAdditions

class XMPPTextMessageInteractionHandler<ViewModel: TextMessageViewModelProtocol>: BaseMessageInteractionHandlerProtocol {
    
    // TODO
    func userDidTapOnFailIcon(viewModel: ViewModel, failIconView: UIView) {}
    func userDidTapOnAvatar(viewModel: ViewModel) {}
    func userDidTapOnBubble(viewModel: ViewModel) {}
    func userDidBeginLongPressOnBubble(viewModel: ViewModel) {}
    func userDidEndLongPressOnBubble(viewModel: ViewModel) {}
}

class XMPPPhotoMessageInteractionHandler: BaseMessageInteractionHandlerProtocol {
    
    private unowned let contextViewController: UIViewController
    
    init(contextViewController: UIViewController) {
        self.contextViewController = contextViewController
    }
    
    func userDidTapOnFailIcon(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>, failIconView: UIView) {
        guard case let .pending(isTransferFailed: true, retryInitiator) = viewModel._photoMessage.transferMonitor.state else {
            // the icon can also be shown after a successful HTTP upload when sending fails for the message itself
            return
        }
        
        let message: String
        switch viewModel.transferDirection.value {
        case .upload:
            message = NSLocalizedString("Upload failed", comment: "")
        case .download:
            message = NSLocalizedString("Download failed", comment: "")
        }
        
        let retryConfirmationSheet = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        retryConfirmationSheet.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default) { _ in
            retryInitiator.invoke()
        })
        retryConfirmationSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        contextViewController.present(retryConfirmationSheet, animated: true, completion: nil)
    }
    
    func userDidTapOnBubble(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {
        guard viewModel.transferStatus.value == .idle else {
            return
        }
    }
    
    // TODO
    func userDidTapOnAvatar(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {}
    func userDidBeginLongPressOnBubble(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {}
    func userDidEndLongPressOnBubble(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {}
}
