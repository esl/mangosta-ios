//
//  ChatViewController+Wallpaper.swift
//  Mangosta
//
//  Created by Sergio Abraham on 3/20/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation

extension ChatViewController {
    private func addConstraints() {
        wallpaperView.setContentHuggingPriority(UILayoutPriority(240), for:
            .horizontal)
        wallpaperView.setContentHuggingPriority(UILayoutPriority(240), for: .vertical)
        wallpaperView.setContentCompressionResistancePriority(UILayoutPriority(240),
                                                              for: .horizontal)
        wallpaperView.setContentCompressionResistancePriority(UILayoutPriority(240),
                                                              for: .vertical)
        view.addConstraint(NSLayoutConstraint(item: wallpaperView, attribute: .top, relatedBy:
            .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: wallpaperView, attribute: .leading,
                                              relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: wallpaperView, attribute: .bottom,
                                              relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: wallpaperView, attribute: .trailing,
                                              relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0))
        wallpaperView.image = UIImage(named: "chat_background")!
        
    }
}
