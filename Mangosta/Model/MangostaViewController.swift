//
//  MangostaViewController.swift
//  Mangosta
//
//  Created by Sergio Abraham on 3/7/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation
class MangostaViewController: UIViewController {
    // This class stores previous TitleView text in an instance var to show the status of xmppReconnect.
    // The new value is set at the TabBarController
    // func resetTitleToDefault uses this value to restore the instance's normal text.
    
    var originalTitle: String?
    let connectingTitle = "Connecting..."
    
    func resetTittleToDefaut() {
        self.navigationItem.title = self.originalTitle
    }
}
