//
//  XMPPCoreDataChatDataSourcePhotoMessageModelProvider.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 03/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Chatto
import ChattoAdditions
import XMPPFramework
import MobileCoreServices
import ImageIO

class XMPPCoreDataChatDataSourcePhotoMessageModelProvider: NSObject, XMPPCoreDataChatDataSourceItemBuilder, XMPPCoreDataChatDataSourceItemEventSource {

    fileprivate class TransferMonitor: NSObject {
        
        class Static: TransferMonitor, PhotoMessageTransferMonitor {
            
            private enum Outcome {
                case pending(isFailed: Bool, message: XMPPMessage, modelProvider: Unowned<XMPPCoreDataChatDataSourcePhotoMessageModelProvider>)
                case successful(previewFileUrl: URL)
            }
            
            private struct Initiator: PhotoMessageTransferInitiator {
                
                let direction: TransferDirection
                let message: XMPPMessage
                unowned let modelProvider: XMPPCoreDataChatDataSourcePhotoMessageModelProvider
                
                func invoke() {
                    switch direction {
                    case .upload:
                        guard let messageId = message.elementID(), let entry = modelProvider.xmppOutOfBandMessagingStorage.entry(forTransferIdentifier: messageId) else {
                            return
                        }
                        modelProvider.xmppOutOfBandMessaging.submitOutgoingMessage(message, withOutOfBandData: entry.data, mimeType: entry.mimeType)
                        
                    case .download:
                        modelProvider.xmppOutOfBandMessaging.retrieveOutOfBandData(for: message)
                    }
                }
            }
            
            private let outcome: Outcome
            
            var state: PhotoMessageTransferMonitorState {
                switch outcome {
                case let .pending(isFailed, message, modelProviderWrapper):
                    return .pending(isTransferFailed: isFailed, Initiator(direction: direction, message: message, modelProvider: modelProviderWrapper.value))
                    
                case .successful(let previewFileUrl):
                    return .done(previewFileUrl: previewFileUrl)
                }
            }
            
            init(successfulOutcomeFor direction: TransferDirection, previewFileUrl: URL) {
                outcome = .successful(previewFileUrl: previewFileUrl)
                super.init(direction: direction)
            }
            
            init (pendingOutcomeFor direction: TransferDirection, isFailed: Bool, message: XMPPMessage, modelProvider: XMPPCoreDataChatDataSourcePhotoMessageModelProvider) {
                outcome = .pending(isFailed: isFailed, message: message, modelProvider: Unowned(value: modelProvider))
                super.init(direction: direction)
            }
            
            override func setObserver(_ observer: PhotoMessageTransferObserver) {
                super.setObserver(observer)
                
                switch outcome {
                case .pending(let isFailed, _, _):
                    observer.notify(ofCurrentStatus: isFailed ? .failed : .idle)
                    
                case .successful:
                    observer.notify(ofCurrentStatus: .success)
                }
            }
        }
        
        class Dynamic: TransferMonitor, PhotoMessageTransferMonitor {
            
            private static var progressFractionCompletedContext = 0
            
            private let progress: Progress
            private var observer: PhotoMessageTransferObserver?

            var state: PhotoMessageTransferMonitorState { return .working }
            
            init(direction: TransferDirection, progress: Progress) {
                self.progress = progress
                super.init(direction: direction)
                
                progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: &Dynamic.progressFractionCompletedContext)
            }
            
            deinit {
                progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), context: &Dynamic.progressFractionCompletedContext)
            }
            
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                guard context == &Dynamic.progressFractionCompletedContext else {
                    super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                    return
                }
                let newFractionCompletedValue = change![.newKey] as! Double
                
                DispatchQueue.main.async {
                    self.observer?.notify(ofCurrentProgress: newFractionCompletedValue)
                }
            }
            
            override func setObserver(_ observer: PhotoMessageTransferObserver) {
                super.setObserver(observer)
                self.observer = observer
                observer.notify(ofCurrentStatus: .transfering)
                observer.notify(ofCurrentProgress: progress.fractionCompleted)
            }
        }
        
        let direction: TransferDirection
        
        private init(direction: TransferDirection) {
            self.direction = direction
        }
        
        func setObserver(_ observer: PhotoMessageTransferObserver) {
            observer.notify(ofCurrentDirection: direction)
        }
    }
    
    private let baseProvider: XMPPCoreDataChatBaseMessageModelProvider
    private let xmppOutOfBandMessaging: XMPPOutOfBandMessaging
    private let xmppOutOfBandMessagingStorage: XMPPOutOfBandMessagingFilesystemStorage
    private let remotePartyJid: XMPPJID
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    init(baseProvider: XMPPCoreDataChatBaseMessageModelProvider, xmppOutOfBandMessaging: XMPPOutOfBandMessaging, xmppOutOfBandMessagingStorage: XMPPOutOfBandMessagingFilesystemStorage, remotePartyJid: XMPPJID) {
        self.baseProvider = baseProvider
        self.xmppOutOfBandMessaging = xmppOutOfBandMessaging
        self.xmppOutOfBandMessagingStorage = xmppOutOfBandMessagingStorage
        self.remotePartyJid = remotePartyJid
    }
    
    func chatItems(at position: XMPPCoreDataChatDataSource.ItemPosition, in messageFetchRequestResults: [MessageFetchRequestResult]) -> [ChatItemProtocol] {
        switch position {
        case .attachedTo(let index):
            guard let (fileThumbnail, fileTransferMonitor) = fileMetadata(for: messageFetchRequestResults[index].source) else {
                return []
            }
            
            let attachedFileItem = TransferAwarePhotoMessageModel(
                messageModel: baseProvider.messageModel(ofType: MessageModel.photoItemType, for: messageFetchRequestResults[index]),
                imageSize: fileThumbnail.size, image: fileThumbnail,
                transferMonitor: fileTransferMonitor
            )
            return [attachedFileItem]
            
        case .tail:
            return xmppOutOfBandMessagingStorage.pendingMessages(forDestinationJID: remotePartyJid).enumerated().flatMap { index, pendingMessage in
                guard let (fileThumbnail, fileTransferMonitor) = fileMetadata(for: pendingMessage) else {
                    return nil
                }
                
                let pendingMessageBaseItem = MessageModel(
                    uid: "pendingMessage/\(pendingMessage.elementID() ?? String(index))/\(MessageModel.photoItemType)",
                    senderId: "pendingMessageSender",
                    type: MessageModel.photoItemType,
                    isIncoming: false,
                    date: messageFetchRequestResults.last?.date ?? Date(),
                    status: .success
                )
                
                return TransferAwarePhotoMessageModel(
                    messageModel: pendingMessageBaseItem,
                    imageSize: fileThumbnail.size, image: fileThumbnail,
                    transferMonitor: fileTransferMonitor
                )
            }
        }
    }
    
    func startObservingChatItemEvents(with sink: XMPPCoreDataChatDataSource.ItemEventSink) {
        xmppOutOfBandMessaging.addDelegate(sink, delegateQueue: .main)
    }
    
    private func fileMetadata(for message: XMPPMessage) -> (UIImage, PhotoMessageTransferMonitor)? {
        guard let messageId = message.elementID() else {
            return nil
        }
        
        let entry = xmppOutOfBandMessagingStorage.entry(forTransferIdentifier: messageId)
        guard message.hasOutOfBandData() || entry != nil else {
            return nil
        }
        
        let thumbnail: UIImage
        if let cachedThumbnail = thumbnailCache.object(forKey: messageId as NSString) {
            thumbnail = cachedThumbnail
        } else if entry?.containsImage == true, let generatedThumbnail = entry?.data?.imageThumbnail(withSizeLimit: 210, for: UIScreen.main) {
            thumbnail = generatedThumbnail
            thumbnailCache.setObject(generatedThumbnail, forKey: messageId as NSString)
        } else if entry?.data != nil {
            // data is there but file type unsupported
            thumbnail = UIImage(named: "ic_attachment_black")!.bma_tintWithColor(.mangostaLightGreen)
        } else {
            // transfer still in progres/failed
            thumbnail = UIImage(named: "ic_file_download_black")!.bma_tintWithColor(.mangostaLightGreen)
        }
        
        let direction: TransferDirection
        switch entry?.kind {
        case .upload?:
            direction = .upload
        case .download?, nil:
            direction = .download
        }
        
        let transferMonitor: PhotoMessageTransferMonitor
        if let progress = xmppOutOfBandMessaging.dataTransferProgress(for: message) {
            transferMonitor = TransferMonitor.Dynamic(direction: direction, progress: progress)
        } else if xmppOutOfBandMessaging.dataTransferError(for: message) != nil {
            transferMonitor = TransferMonitor.Static(pendingOutcomeFor: direction, isFailed: true, message: message, modelProvider: self)
        } else if let entry = entry, entry.isTransferComplete {
            transferMonitor = TransferMonitor.Static(successfulOutcomeFor: direction, previewFileUrl: entry.fileURL)
        } else {
            let isFailed = direction == .upload // there are no idle uploads, only successful/failed ones
            transferMonitor = TransferMonitor.Static(pendingOutcomeFor: direction, isFailed: isFailed, message: message, modelProvider: self)
        }
        
        return (thumbnail, transferMonitor)
    }
}

extension XMPPCoreDataChatDataSource.ItemEventSink: XMPPOutOfBandMessagingDelegate {
    
    func xmppOutOfBandMessaging(_ xmppOutOfBandMessaging: XMPPOutOfBandMessaging!, didBeginDataTransferFor message: XMPPMessage!) {
        invalidateCurrentChatItems()
    }
    
    func xmppOutOfBandMessaging(_ xmppOutOfBandMessaging: XMPPOutOfBandMessaging!, didPrepareDataTransferStorageEntryFor message: XMPPMessage!) {
        invalidateCurrentChatItems()
    }
    
    func xmppOutOfBandMessaging(_ xmppOutOfBandMessaging: XMPPOutOfBandMessaging!, didCompleteDataTransferFor message: XMPPMessage!) {
        invalidateCurrentChatItems()
    }
    
    func xmppOutOfBandMessaging(_ xmppOutOfBandMessaging: XMPPOutOfBandMessaging!, didFailDataTransferFor message: XMPPMessage!) {
        invalidateCurrentChatItems()
    }
}

private extension XMPPOutOfBandMessagingFilesystemStorageEntry {
    
    var containsImage: Bool {
        guard let mimeType = self.mimeType, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    
    var data: Data? {
        return kind == .upload || isTransferComplete ? try? Data(contentsOf: fileURL, options: .mappedIfSafe) : nil
    }
}

private extension Data {
    
    func imageThumbnail(withSizeLimit sizeLimit: CGFloat, for screen: UIScreen) -> UIImage? {
        let options: [String: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
            kCGImageSourceCreateThumbnailWithTransform as String: true,
            kCGImageSourceThumbnailMaxPixelSize as String: sizeLimit * screen.scale
        ]
        
        return CGImageSourceCreateWithData(self as CFData, nil)
            .flatMap { CGImageSourceCreateThumbnailAtIndex($0, 0, options as CFDictionary) }
            .flatMap { UIImage(cgImage: $0, scale: screen.scale, orientation: .up) }
    }
}

private struct Unowned<T: AnyObject> {
    unowned let value: T
}
