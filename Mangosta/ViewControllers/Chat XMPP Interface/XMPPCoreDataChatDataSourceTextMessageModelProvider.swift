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
    
    private struct CorrectionHandler: TextMessageCorrectionHandler {
        
        let originalMessage: XMPPMessage
        let recipientJid: XMPPJID
        let currentText: String
        let xmppStream: XMPPStream
        
        func sendCorrection(withText correctedText: String) {
            let correctionMessage = originalMessage.generateCorrectionMessage(withID: XMPPStream.generateUUID(), body: correctedText)!
            
            // In some, cases "to" may be missing/wrong on the original message (e.g. MAM archives in MUC rooms)
            correctionMessage.removeAttribute(forName: "to")
            correctionMessage.addAttribute(withName: "to", stringValue: recipientJid.full())
            
            // Similarly, "from" may be present and incorrect (again, MAM/MUC case)
            correctionMessage.removeAttribute(forName: "from")
            
            xmppStream.send(correctionMessage)
        }
    }
    
    private let baseProvider: XMPPCoreDataChatBaseMessageModelProvider
    private let xmppRoster: XMPPRoster
    private let xmppStream: XMPPStream
    private let correctionRecipientJid: XMPPJID
    
    init(baseProvider: XMPPCoreDataChatBaseMessageModelProvider, xmppRoster: XMPPRoster, xmppStream: XMPPStream, correctionRecipientJid: XMPPJID) {
        self.baseProvider = baseProvider
        self.xmppRoster = xmppRoster
        self.xmppStream = xmppStream
        self.correctionRecipientJid = correctionRecipientJid
    }
    
    func chatItems(at position: XMPPCoreDataChatDataSource.ItemPosition, in messageFetchRequestResults: [MessageFetchRequestResult]) -> [ChatItemProtocol] {
        guard case let .attachedTo(index) = position, let body = messageFetchRequestResults[index].source.body(), !body.isEmpty, !messageFetchRequestResults[index].source.isMessageCorrection() else {
            return []
        }
        
        let originalResult = messageFetchRequestResults[index]
        let correctedResult = messageFetchRequestResults.correction(forResultAt: index)
        let finalResult = correctedResult ?? originalResult
        let correctableResult = messageFetchRequestResults.isResultCorrectable(at: index, inStreamWithLocalJid: xmppStream.myJID) ? originalResult : nil
        
        let textItem = CorrectionAwareTextMessageModel(
            messageModel: baseProvider.messageModel(ofType: MessageModel.textItemType, for: finalResult),
            text: xmppRoster.transformedTextContent(for: finalResult.source),
            isCorrected: correctedResult != nil,
            correctionHandler: correctableResult.map {
                CorrectionHandler(originalMessage: $0.source, recipientJid: correctionRecipientJid, currentText: finalResult.source.body(), xmppStream: xmppStream)
            }
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

// TODO: don't use a dummy MessageFetchRequestResult implementation
private class MessageFetchRequestResultReplacement: NSObject, MessageFetchRequestResult {
    
    let replacedResult: MessageFetchRequestResult
    let replacementSource: XMPPMessage
    
    var source: XMPPMessage { return replacementSource }
    var uid: String { return replacedResult.uid }
    var senderId: String { return replacedResult.senderId }
    var isIncoming: Bool { return replacedResult.isIncoming }
    var date: Date { return replacedResult.date }
    
    init(replacedResult: MessageFetchRequestResult, replacementSource: XMPPMessage) {
        self.replacedResult = replacedResult
        self.replacementSource = replacementSource
    }

    func isChatOriginContinuityMaintained(with other: MessageFetchRequestResult) -> Bool {
        return replacedResult.isChatOriginContinuityMaintained(with: other)
    }
    
    func isChatOriginContinuityMaintained(inStreamWithLocalJid streamLocalJid: XMPPJID) -> Bool {
        return replacedResult.isChatOriginContinuityMaintained(inStreamWithLocalJid: streamLocalJid)
    }
}

private extension Array where Element == MessageFetchRequestResult {
    
    func isResultCorrectable(at index: Int, inStreamWithLocalJid streamLocalJid: XMPPJID) -> Bool {
        return self[index].isChatOriginContinuityMaintained(inStreamWithLocalJid: streamLocalJid) && correctionScope(forResultAt: index).endIndex == endIndex
    }
    
    func correction(forResultAt index: Int) -> MessageFetchRequestResult? {
        return correctionScope(forResultAt: index).reversed().first { result in
            result.source.isMessageCorrection() && result.source.correctedMessageID() == self[index].source.elementID()
        }
    }
    
    func correctionScope(forResultAt index: Int) -> ArraySlice<MessageFetchRequestResult> {
        return suffix(from: self.index(after: index)).prefix { result in
            self[index].isChatOriginContinuityMaintained(with: result) &&
                (result.senderId != self[index].senderId || result.source.isMessageCorrection())
        }
    }
}
