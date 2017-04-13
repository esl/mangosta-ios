//
//  AboutViewController.swift
//  Mangosta
//
//  Created by Sergio Abraham on 2/6/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation

class AboutViewController: UIViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.versionLabel.text = self.loadVersionAndBuildNumber()
    }
    func loadVersionAndBuildNumber() -> String {
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        return "Version " + version! + " Build " + build!
    }
}
