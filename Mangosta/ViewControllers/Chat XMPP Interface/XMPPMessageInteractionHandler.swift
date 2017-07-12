//
//  XMPPMessageInteractionHandler.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import ChattoAdditions
import QuickLook
import XMPPFramework

class XMPPTextMessageInteractionHandler<ViewModel: TextMessageViewModelProtocol>: BaseMessageInteractionHandlerProtocol {
    
    // TODO
    func userDidTapOnFailIcon(viewModel: ViewModel, failIconView: UIView) {}
    func userDidTapOnAvatar(viewModel: ViewModel) {}
    func userDidTapOnBubble(viewModel: ViewModel) {}
    func userDidBeginLongPressOnBubble(viewModel: ViewModel) {}
    func userDidEndLongPressOnBubble(viewModel: ViewModel) {}
}

class XMPPPhotoMessageInteractionHandler: NSObject, BaseMessageInteractionHandlerProtocol, QLPreviewControllerDelegate {
    
    private unowned let contextViewController: UIViewController
    private var currentPreviewControllerDataSource: QLPreviewControllerDataSource?
    
    init(contextViewController: UIViewController) {
        self.contextViewController = contextViewController
    }
    
    func userDidTapOnFailIcon(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>, failIconView: UIView) {
        guard case let .pending(isTransferFailed: true, retryInitiator) = viewModel._photoMessage.transferMonitor.state else {
            // the icon can also be shown after a successful HTTP upload when sending fails for the message itself
            return
        }
        
        retryTransfer(for: viewModel, with: retryInitiator)
    }
    
    func userDidTapOnBubble(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {
        switch viewModel._photoMessage.transferMonitor.state {
        case let .pending(isTransferFailed, transferInitiator):
            if isTransferFailed {
                // notify the user that a transfer has failed before and ask for confirmation before retrying
                retryTransfer(for: viewModel, with: transferInitiator)
            } else {
                // no previous failure information available; assume this is the initial transfer attempt and proceed without confirmation
                transferInitiator.invoke()
            }
            
        case .done(let previewFileUrl):
            if let previewControllerDataSource = viewModel._photoMessage._messageModel.previewControllerDataSource(withFileUrl: previewFileUrl) {
                let previewController = QLPreviewController()

                previewController.dataSource = previewControllerDataSource
                currentPreviewControllerDataSource = previewControllerDataSource

                previewController.delegate = self

                contextViewController.present(previewController, animated: true, completion: nil)
            }
            
        case .working:
            break
        }
    }
    
    // TODO
    func userDidTapOnAvatar(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {}
    func userDidBeginLongPressOnBubble(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {}
    func userDidEndLongPressOnBubble(viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>) {}
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        currentPreviewControllerDataSource = nil
    }
    
    private func retryTransfer(for viewModel: PhotoMessageViewModel<TransferAwarePhotoMessageModel<MessageModel>>, with retryInitiator: PhotoMessageTransferInitiator) {
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
}

private extension MessageModel {
    
    class PreviewItem: NSObject, QLPreviewControllerDataSource, QLPreviewItem {
        
        let title: String
        let fileUrl: URL
        
        var previewItemURL: URL? { return fileUrl }
        var previewItemTitle: String? { return title }
        
        init(title: String, fileUrl: URL) {
            self.title = title
            self.fileUrl = fileUrl
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return self
        }
    }
    
    func previewControllerDataSource(withFileUrl previewFileUrl: URL) -> QLPreviewControllerDataSource? {
        let title = XMPPJID(string: senderId)?.user ?? senderId
        let previewItem = PreviewItem(title: title, fileUrl: previewFileUrl)
        return QLPreviewController.canPreview(previewItem) ? previewItem : nil
    }
}
