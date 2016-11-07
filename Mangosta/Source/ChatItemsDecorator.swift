//
//  ChatItemsDecorator.swift
//  Demo
//
//  Created by little2s on 16/5/10.
//  Copyright © 2016年 little2s. All rights reserved.
//

import Foundation
//import NoChat
//import NoChatTG
//import NoChatMM
//import NoChatSLK

// MARK: Telegram style

typealias TGDateItem = DateItem
typealias TGChatItemDecorationAttributes = ChatItemDecorationAttributes

class TGChatItemsDecorator: ChatItemsDecoratorProtocol {
    lazy var dateItem: TGDateItem = {
        let dateUid = NSUUID().UUIDString
        return TGDateItem(uid: dateUid, date: NSDate())
    }()
    
    func decorateItems(chatItems: [ChatItemProtocol], inverted: Bool) -> [DecoratedChatItem] {
        let bottomMargin: CGFloat = 2
        
        var decoratedChatItems = [DecoratedChatItem]()
        
        for chatItem in chatItems {
            decoratedChatItems.append(
                DecoratedChatItem(
                    chatItem: chatItem,
                    decorationAttributes: TGChatItemDecorationAttributes(bottomMargin: bottomMargin, showsTail: true)
                )
            )
        }
        
        if chatItems.isEmpty == false {
            let decoratedDateItem = DecoratedChatItem(
                chatItem: dateItem,
                decorationAttributes: TGChatItemDecorationAttributes(bottomMargin: bottomMargin, showsTail: false)
            )
            decoratedChatItems.append(decoratedDateItem)
        }
        
        return decoratedChatItems
    }
}


