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
	
	func loadNext(_ completion: () -> Void) {
		completion()
	}
	
	func loadPrevious(_ completion: () -> Void) {
		completion()
	}
	
	func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion:(_ didAdjust: Bool) -> Void) {
		completion(false)
	}
	
	
	func addMessages(_ messages: [NoChatMessage]) {
		chatItems.insert(contentsOf: messages.reversed().map { $0 as ChatItemProtocol }, at: 0)
		delegate?.chatDataSourceDidUpdate(self)
	}
	
}

class ChatItemsDecorator: ChatItemsDecoratorProtocol {
	lazy var dateItem: TGDateItem = {
		let dateUid = UUID().uuidString
		return TGDateItem(uid: dateUid, date: Date())
	}()
	
	func decorateItems(_ chatItems: [ChatItemProtocol], inverted: Bool) -> [DecoratedChatItem] {
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
