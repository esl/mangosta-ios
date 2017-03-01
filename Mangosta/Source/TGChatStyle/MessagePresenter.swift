//
//  MessagePresenter.swift
//  NoChat
//
//  Created by little2s on 16/3/19.
//  Copyright © 2016年 Ninty. All rights reserved.
//

import UIKit
//import NoChat

public class MessagePresenter<BubbleViewT, ViewModelBuilderT where
    BubbleViewT: UIView,
    BubbleViewT: BubbleViewProtocol,
    ViewModelBuilderT: MessageViewModelBuilderProtocol>: BaseChatItemPresenter<MessageCollectionViewCell<BubbleViewT>> {
    // MARK: Types
    typealias ModelT = MessageProtocol
    typealias CellT = MessageCollectionViewCell<BubbleViewT>
    typealias ViewModelT = MessageViewModelProtocol
    
    // MARK: Properties
    let message: ModelT
    let sizingCell: MessageCollectionViewCell<BubbleViewT>
    let viewModelBuilder: ViewModelBuilderT
    let layoutCache: NSCache
    
    private(set) final lazy var messageViewModel: ViewModelT = {
        return self.createViewModel()
    }()
    
    var decorationAttributes: ChatItemDecorationAttributes!
    
    static var bubbleIdentifier: String {
        return BubbleViewT.bubbleIdentifier
    }
    
    static var incomingCellIdentifier: String {
        return "MessageCollectionCellIncoming-\(bubbleIdentifier)"
    }
    
    static var outgoingCellIdentifier: String {
        return "MessageCollectionCellOutgoing-\(bubbleIdentifier)"
    }
    
    var incomingCellIdentifier: String {
        return MessagePresenter<BubbleViewT, ViewModelBuilderT>.incomingCellIdentifier
    }
    
    var outgoingCellIdentifier: String {
        return MessagePresenter<BubbleViewT, ViewModelBuilderT>.outgoingCellIdentifier
    }
    
    // MARK: Initialization
    init(message: ModelT, sizingCell: CellT, viewModelBuilder: ViewModelBuilderT, layoutCache: NSCache) {
        self.message = message
        self.sizingCell = sizingCell
        self.viewModelBuilder = viewModelBuilder
        self.layoutCache = layoutCache
    }
    
    // MARK: Override
    public override static func registerCells(collectionView: UICollectionView) {
        collectionView.registerClass(CellT.self, forCellWithReuseIdentifier: incomingCellIdentifier)
        collectionView.registerClass(CellT.self, forCellWithReuseIdentifier: outgoingCellIdentifier)
    }
    
    public override func dequeueCell(collectionView collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = messageViewModel.isIncoming ? incomingCellIdentifier : outgoingCellIdentifier
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! MessageCollectionViewCell<BubbleViewT>
        UIView.performWithoutAnimation {
            cell.contentView.transform = collectionView.transform
        }
        cell.selected = true
        cell.onBubbleLongPressBegan = { (cell) in
            if cell.bubbleView.messageViewModel.isIncoming == false && cell.isLastRow {
                cell.becomeFirstResponder()
    
                let menuController = UIMenuController.sharedMenuController()
                menuController.setTargetRect(cell.bubbleView.frame, inView: cell)
                menuController.setMenuVisible(true, animated:true)
                let menuEntries = [MessageCorrectionUIMenuItem.init(title: "Edit message", action: #selector(ChatViewController.correctLastSentMessageFromMenuController(_:)), messageID: cell.bubbleView.messageViewModel.message.msgId)]
                menuController.menuItems = menuEntries
                menuController.update()
            }

       // self.showAlertForRow(collectionView.indexPathForCell(cell)!.row)
        }
        return cell
    }
    
    public final override func configureCell(cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let cell = cell as? CellT else {
            assert(false, "Invalid cell given to presenter")
            return
        }
        
        guard let decorationAttributes = decorationAttributes as? ChatItemDecorationAttributes else {
            assert(false, "Expecting decoration attributes")
            return
        }
        
        self.decorationAttributes = decorationAttributes
        self.configureCell(cell, decorationAttributes: decorationAttributes, animated: false, additionConfiguration: nil)
    }
    
    public override func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        guard let attr = decorationAttributes as? ChatItemDecorationAttributes else {
            assert(false, "Expecting decoration attributes")
            return 0
        }
        configureCell(sizingCell, decorationAttributes: attr, animated: false, additionConfiguration: nil)
        return sizingCell.cellSizeThatFits(CGSize(width: width, height: CGFloat.max)).height
    }
    
    public override var canCalculateHeightInBackground: Bool {
        return sizingCell.canCalculateSizeInBackground
    }
    
    public override func shouldShowMenu() -> Bool {
        return false
    }
    
    public override func canPerformMenuControllerAction(action: Selector) -> Bool {
        return true
    }
    
    public override func performMenuControllerAction(action: Selector) {
        print("TODO: ")
    }
    
    // MARK: Convenience
    func createViewModel() -> ViewModelT {
        let viewModel = viewModelBuilder.createMessageViewModel(message: message)
        return viewModel
    }
    
    func configureCell(cell: CellT, decorationAttributes: ChatItemDecorationAttributes, animated: Bool, additionConfiguration: (() -> Void)?) {
        cell.performBatchUpdates({ () -> Void in
            cell.layoutCache = self.layoutCache
            cell.messageViewModel = self.messageViewModel
            if let currentMessageViewModel = cell.bubbleView.messageViewModel {
                if currentMessageViewModel.isIncoming == false {
                    cell.bubbleView.addGestureRecognizer(cell.longPressGestureRecognizer)
                }
            }
            additionConfiguration?()
        }, animated: false, completion: nil)
    }

}
