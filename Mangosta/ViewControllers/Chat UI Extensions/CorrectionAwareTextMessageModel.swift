//
//  CorrectionAwareTextMessageModel.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 17/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Chatto
import ChattoAdditions

class CorrectionAwareTextMessageModel<MessageModelT: MessageModelProtocol>: TextMessageModel<MessageModelT> {

    let correctionHandler: TextMessageCorrectionHandler?
    
    init(messageModel: MessageModelT, text: String, isCorrected: Bool, correctionHandler: TextMessageCorrectionHandler?) {
        self.correctionHandler = correctionHandler
        super.init(messageModel: messageModel, text: isCorrected ? "✎ \(text)" : text)
    }
}

protocol TextMessageCorrectionHandler {
    
    var currentText: String { get }
    func sendCorrection(withText correctedText: String)
}
