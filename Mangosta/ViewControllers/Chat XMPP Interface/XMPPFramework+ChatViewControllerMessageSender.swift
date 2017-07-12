//
//  XMPPFramework+ChatViewControllerMessageSender.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 31/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework
import MobileCoreServices

extension XMPPOneToOneChatSession: ChatViewControllerMessageSender {
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithText messageText: String) {
        sendMessage(withBody: messageText)
    }
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithImage messageImage: UIImage) {
        // TODO: Chatto's default provider only delivers decompressed UIImage, ideally we'd like to receive the original compressed data here
        sendMessage(with: messageImage)
    }
}

extension XMPPRoomLight: ChatViewControllerMessageSender {
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithText messageText: String) {
        // TODO: encapsulate ID injection in XMPPRoomLight
        let message = XMPPMessage()!
        message.addAttribute(withName: "id", stringValue: XMPPStream.generateUUID())
        message.addChild(DDXMLElement(name: "body", stringValue: messageText))
        send(message)
    }
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithImage messageImage: UIImage) {
        // TODO: Chatto's default provider only delivers decompressed UIImage, ideally we'd like to receive the original compressed data here
        sendMessage(with: messageImage)
    }
}

private protocol OutOfBandDataMessageSender {
    
    func sendMessage(withOutOfBandData: Data!, mimeType: String!)
}

extension OutOfBandDataMessageSender {
    
    func sendMessage(with image: UIImage) {
        let data: Data
        let utType: CFString
        if let utTypeIn = image.cgImage?.utType, utTypeIn == kUTTypePNG {
            data = UIImagePNGRepresentation(image)!
            utType = kUTTypePNG
        } else {
            data = UIImageJPEGRepresentation(image, 1)!
            utType = kUTTypeJPEG
        }
        
        guard let mimeType = UTTypeCopyPreferredTagWithClass(utType, kUTTagClassMIMEType)?.takeRetainedValue() else {
            return
        }
        sendMessage(withOutOfBandData: data, mimeType: mimeType as String)
    }
}

extension XMPPOneToOneChatSession: OutOfBandDataMessageSender {}
extension XMPPRoomLight: OutOfBandDataMessageSender {}
