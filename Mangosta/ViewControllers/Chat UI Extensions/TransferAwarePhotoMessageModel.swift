//
//  TransferAwarePhotoMessageModel.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 03/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import ChattoAdditions

class TransferAwarePhotoMessageModel<MessageModelT: MessageModelProtocol>: PhotoMessageModel<MessageModelT> {

    let transferMonitor: PhotoMessageTransferMonitor
    
    init(messageModel: MessageModelT, imageSize: CGSize, image: UIImage, transferMonitor: PhotoMessageTransferMonitor) {
        self.transferMonitor = transferMonitor
        super.init(messageModel: messageModel, imageSize: imageSize, image: image)
    }
}

class TransferAwarePhotoMessageViewModelDefaultBuilder<MessageModelT: MessageModelProtocol, PhotoMessageModelT: TransferAwarePhotoMessageModel<MessageModelT>>: PhotoMessageViewModelDefaultBuilder<PhotoMessageModelT> {
    
    override func createViewModel(_ model: PhotoMessageModelT) -> PhotoMessageViewModel<PhotoMessageModelT> {
        let photoMessageViewModel = super.createViewModel(model)
        model.transferMonitor.setObserver(photoMessageViewModel)
        return photoMessageViewModel
    }
}

protocol PhotoMessageTransferMonitor {
    
    func setObserver(_ observer: PhotoMessageTransferObserver)
}

protocol PhotoMessageTransferObserver {
    
    func notify(ofCurrentStatus currentStatus: TransferStatus)
    func notify(ofCurrentProgress currentProgress: Double)
    func notify(ofCurrentDirection currentDirection: TransferDirection)
}

extension PhotoMessageViewModel: PhotoMessageTransferObserver {
    
    func notify(ofCurrentStatus currentStatus: TransferStatus) {
        transferStatus.value = currentStatus
    }
    
    func notify(ofCurrentProgress currentProgress: Double) {
        transferProgress.value = currentProgress
    }
    
    func notify(ofCurrentDirection currentDirection: TransferDirection) {
        transferDirection.value = currentDirection
    }
}
