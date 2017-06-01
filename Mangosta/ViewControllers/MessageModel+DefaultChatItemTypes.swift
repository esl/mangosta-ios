//
//  MessageModel+DefaultChatItemTypes.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Chatto
import ChattoAdditions

extension MessageModel {
    
    static var textItemType: ChatItemType {
        return "text"
    }
    
    static var photoItemType: ChatItemType {
        return "photo"
    }
}
