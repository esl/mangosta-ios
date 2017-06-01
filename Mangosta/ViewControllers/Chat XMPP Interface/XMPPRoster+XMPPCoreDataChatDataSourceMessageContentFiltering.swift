//
//  XMPPRoster+XMPPCoreDataChatDataSourceMessageContentFiltering.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 31/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

extension XMPPRoster: XMPPCoreDataChatDataSourceMessageContentFiltering {
    
    func xmppCoreDataChatDataSource(_ dataSource: XMPPCoreDataChatDataSource, willCreateMessageModelWithTextContent textContent: String, for message: XMPPMessage) -> String {
        // TODO: should have a designated chat item type for "me" commands
        if (textContent as NSString).hasXMPPMeCommandPrefix(), let substitution = meCommandSubstitution(for: message) {
            return "\(substitution) \((textContent as NSString).xmppMessageBodyStringByTrimmingMeCommand()!)"
        } else {
            return textContent
        }
    }
}
