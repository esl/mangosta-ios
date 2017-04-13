/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import Foundation
import Chatto
import ChattoAdditions

public protocol MessageModelProtocol: MessageModelProtocol {
    var status: MessageStatus { get set }
}

public class QueueMessageSender {

    public var onMessageChanged: ((_ message: MessageModelProtocol) -> Void)?

    public func sendMessages(messages: [MessageModelProtocol]) {
        for message in messages {
            self.queueMessageStatus(message: message)
        }
    }

    public func sendMessage( message: MessageModelProtocol) {
        self.queueMessageStatus(message: message)
    }

    private func queueMessageStatus( message: MessageModelProtocol) {
        // TODO: include status from server
        switch message.status {
        case .success:
            break
        case .failed:
            self.updateMessage(message, status: .sending)
            self.queueMessageStatus(message: message)
        case .sending:
            // TODO: adapt this method to resend message
            let controller = ChatViewController()
            controller.sendMessageToServer(message as? TextMessageModel)
            
            // TODO: use message status from xmpp
            let delaySeconds: Double = Double(arc4random_uniform(1200)) / 1000.0
            let delayTime = DispatchTime.now() + Double(Int64(delaySeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.updateMessage(message, status: .success)
                self.queueMessageStatus(message: message)
            }
        }
    }

    private func updateMessage(_ message: MessageModelProtocol, status: MessageStatus) {
        if message.status != status {
            message.status = status
            self.notifyMessageChanged(message)
        }
    }

    private func notifyMessageChanged(_ message: MessageModelProtocol) {
        self.onMessageChanged?(message)
    }
}
