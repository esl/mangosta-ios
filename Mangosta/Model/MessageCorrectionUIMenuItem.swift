//
//  MessageCorrectionUIMenuItem.swift
//  Mangosta
//
//  Created by Sergio Abraham on 2/24/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation

class MessageCorrectionUIMenuItem: UIMenuItem {
    var messageIDForCorrection: String?
    init(title: String, action: Selector, messageID: String?) {
        super.init(title: title, action: action)
        self.messageIDForCorrection = messageID
    }
}
