//
//  XMPPFramework+ChatViewControllerMessageSender.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 31/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

extension XMPPOneToOneChatSession: ChatViewControllerMessageSender {
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithText messageText: String) {
        sendMessage(withBody: messageText)
    }
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithImage messageImage: UIImage) {
        // TODO
    }
}

extension XMPPRoomLight: ChatViewControllerMessageSender {
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithText messageText: String) {
        sendMessage(withBody: messageText)
    }
    
    func chatViewController(_ viewController: ChatViewController, didRequestToSendMessageWithImage messageImage: UIImage) {
        // TODO
    }
}
