//
//  XMPPMessageInteractionHandler.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 30/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import ChattoAdditions

class XMPPMessageInteractionHandler<ViewModel: MessageViewModelProtocol>: BaseMessageInteractionHandlerProtocol {
    
    // TODO
    func userDidTapOnFailIcon(viewModel: ViewModel, failIconView: UIView) {}
    func userDidTapOnAvatar(viewModel: ViewModel) {}
    func userDidTapOnBubble(viewModel: ViewModel) {}
    func userDidBeginLongPressOnBubble(viewModel: ViewModel) {}
    func userDidEndLongPressOnBubble(viewModel: ViewModel) {}
}
