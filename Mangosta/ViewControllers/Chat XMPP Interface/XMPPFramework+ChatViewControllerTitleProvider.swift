//
//  XMPPFramework+ChatViewControllerTitleProvider.swift
//  Mangosta
//
//  Created by Piotrek on 17/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

class XMPPOneToOneChatTitleProvider: ChatViewControllerTitleProvider {
    
    let chatTitle: String
    
    init(user: XMPPUser) {
        chatTitle = user.jid().user
    }
}

class XMPPRoomLightChatTitleProvider: ChatViewControllerTitleProvider, XMPPRoomLightDelegate {
    
    private(set) var chatTitle = ""
    weak var delegate: ChatViewControllerTitleProviderDelegate?
    
    init(room: XMPPRoomLight) {
        room.addDelegate(self, delegateQueue: .main)
        updateChatTitle(with: room)
    }
    
    func xmppRoomLight(_ sender: XMPPRoomLight, configurationChanged message: XMPPMessage) {
        updateChatTitle(with: sender)
        delegate?.chatViewControllerTitleProviderDidChangeTitle(self)
    }
    
    private func updateChatTitle(with room: XMPPRoomLight) {
        chatTitle = room.roomname()
    }
}
