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

extension Array {
    func randomItem() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

func createTextMessageModel(_ uid: String, text: String, isIncoming: Bool) -> DemoTextMessageModel {
    let messageModel = createMessageModel(uid, isIncoming: isIncoming, type: TextMessageModel<MessageModel>.chatItemType)
    let textMessageModel = DemoTextMessageModel(messageModel: messageModel, text: text)
    return textMessageModel
}

func createMessageModel(_ uid: String, isIncoming: Bool, type: String) -> MessageModel {
    let senderId = uid
    let messageStatus = MessageStatus.sending
    let messageModel = MessageModel(uid: uid, senderId: senderId, type: type, isIncoming: isIncoming, date: Date(), status: messageStatus)
    return messageModel
}

func createPhotoMessageModel(_ uid: String, image: UIImage, size: CGSize, isIncoming: Bool) -> DemoPhotoMessageModel {
    let messageModel = createMessageModel(uid, isIncoming: isIncoming, type: PhotoMessageModel<MessageModel>.chatItemType)
    let photoMessageModel = DemoPhotoMessageModel(messageModel: messageModel, imageSize:size, image: image)
    return photoMessageModel
}

class QueueMessageFactory {

    class func createChatItem(_ uid: String, text: String) -> MessageModelProtocol {
        return self.createOutgoingTextMessageModel(uid, text: text)
    }

    class func createOutgoingTextMessageModel(_ uid: String, text: String) -> DemoTextMessageModel {
        let isIncoming: Bool = false
        
        #if MangostaREST
            return Mangosta_REST.createTextMessageModel(uid, text: text, isIncoming: isIncoming)
        #else
            return Mangosta.createTextMessageModel(uid, text: text, isIncoming: isIncoming)
        #endif
    }

    class func createPhotoMessageModel(_ uid: String, isIncoming: Bool) -> DemoPhotoMessageModel {
        var imageSize = CGSize.zero
        switch arc4random_uniform(100) % 3 {
        case 0:
            imageSize = CGSize(width: 400, height: 300)
        case 1:
            imageSize = CGSize(width: 300, height: 400)
        case 2:
            fallthrough
        default:
            imageSize = CGSize(width: 300, height: 300)
        }

        var imageName: String
        switch arc4random_uniform(100) % 3 {
        case 0:
            imageName = "pic-test-1"
        case 1:
            imageName = "pic-test-2"
        case 2:
            fallthrough
        default:
            imageName = "pic-test-3"
        }
        #if MangostaREST
            return Mangosta_REST.createPhotoMessageModel(uid, image: UIImage(named: imageName)!, size: imageSize, isIncoming: isIncoming)
        #else
            return Mangosta.createPhotoMessageModel(uid, image: UIImage(named: imageName)!, size: imageSize, isIncoming: isIncoming)
        #endif
    }
}

extension TextMessageModel {
    static var chatItemType: ChatItemType {
        return "text"
    }
}

extension PhotoMessageModel {
    static var chatItemType: ChatItemType {
        return "photo"
    }
}

class TutorialMessageFactory {
    static let messages = [
        ("text", "Test message."),
        ("image", "pic-test-1")
    ]

    static func createMessages() -> [MessageModelProtocol] {
        var result = [MessageModelProtocol]()
        for (index, message) in self.messages.enumerated() {
            let type = message.0
            let content = message.1
            let isIncoming: Bool = arc4random_uniform(100) % 2 == 0

            if type == "text" {
                result.append(createTextMessageModel("tutorial-\(index)", text: content, isIncoming: isIncoming))
            } else {
                let image = UIImage(named: content)!
                result.append(createPhotoMessageModel("tutorial-\(index)", image:image, size: image.size, isIncoming: isIncoming))
            }
        }
        return result
    }
}
