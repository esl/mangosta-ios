//
//  XMPPCoreDataChatDataSourceTextMessageModelProvider.swift
//  Mangosta
//
//  Created by Piotrek on 02/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Chatto
import ChattoAdditions
import XMPPFramework

class XMPPCoreDataChatDataSourceTextMessageModelProvider: NSObject, XMPPCoreDataChatDataSourceItemBuilder {
    
    private let baseProvider: XMPPCoreDataChatBaseMessageModelProvider
    private let xmppRoster: XMPPRoster
    
    init(baseProvider: XMPPCoreDataChatBaseMessageModelProvider, xmppRoster: XMPPRoster) {
        self.baseProvider = baseProvider
        self.xmppRoster = xmppRoster
    }
    
    func chatItems(at position: XMPPCoreDataChatDataSource.ItemPosition, in messageFetchRequestResults: [MessageFetchRequestResult]) -> [ChatItemProtocol] {
        guard case let .attachedTo(index) = position, let body = messageFetchRequestResults[index].source.body(), !body.isEmpty else {
            return []
        }
        
        let textItem = TextMessageModel(
            messageModel: baseProvider.messageModel(ofType: MessageModel.textItemType, for: messageFetchRequestResults[index]),
            text: xmppRoster.transformedTextContent(for: messageFetchRequestResults[index].source)
        )
        return [textItem]
    }
}

private extension XMPPRoster {
    
    func transformedTextContent(for message: XMPPMessage) -> String {
        // TODO: should have a designated chat item type for "me" commands
        if (message.body() as NSString).hasXMPPMeCommandPrefix(), let substitution = meCommandSubstitution(for: message) {
            return "\(substitution) \((message.body() as NSString).xmppMessageBodyStringByTrimmingMeCommand()!)"
        } else {
            return message.body()
        }
    }
}
