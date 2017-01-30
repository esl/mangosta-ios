//
//  SocialMedia.swift
//  Mangosta
//
//  Created by Sergio Abraham on 11/17/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import UIKit
import XMPPFramework
import MBProgressHUD

class SocialMediaViewController: UIViewController {
    @IBOutlet internal var tableView: UITableView!
	override func viewDidLoad() {
	
        let darkGreenColor = "009ab5"
        let lightGreenColor = "58cfe4"
                
       	let addBlogEntryButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(addBlogButtonPressed(_:)))
        addBlogEntryButton.tintColor = UIColor(hexString:darkGreenColor)
        self.navigationItem.rightBarButtonItems = [addBlogEntryButton]
        
        
        MangostaSettings().setNavigationBarColor()
        
        self.tableView.backgroundColor = UIColor(hexString:lightGreenColor)
        
	}
    
    func addBlogButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController.textFieldAlertController("Create Blog Post", message: "Enter text here") { (blogString) in
            if let blogID = XMPPJID.jidWithString(blogString) {
                self.showHUDwithMessage("Publishing...")
                // TODO: self.microBlog.publish(blogID)
                // TODO: add in callback 
                MBProgressHUD.hideHUDForView(self.view, animated: true)
            }
        }
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}

extension SocialMediaViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
}

extension SocialMediaViewController {
    func showHUDwithMessage(message: String) {
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.labelText = message
    }
}

