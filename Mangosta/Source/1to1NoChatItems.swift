//
//  1to1NoChatItems.swift
//  Mangosta
//
//  Created by Sergio Abraham on 11/10/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

class ChatDataSourceInterface: ChatDataSourceProtocol {
	var hasMoreNext: Bool = false
	var hasMorePrevious: Bool = false
	var chatItems: [ChatItemProtocol] = []
	weak var delegate: ChatDataSourceDelegateProtocol?
	
	func loadNext(completion: () -> Void) {
		completion()
	}
	
	func loadPrevious(completion: () -> Void) {
		completion()
	}
	
	func adjustNumberOfMessages(preferredMaxCount preferredMaxCount: Int?, focusPosition: Double, completion:(didAdjust: Bool) -> Void) {
		completion(didAdjust: false)
	}
	
	
	func addMessages(messages: [NoChatMessage]) {
		chatItems.insertContentsOf(messages.reverse().map { $0 as ChatItemProtocol }, at: 0)
		delegate?.chatDataSourceDidUpdate(self)
	}
	
}

class ChatItemsDecorator: ChatItemsDecoratorProtocol {
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
