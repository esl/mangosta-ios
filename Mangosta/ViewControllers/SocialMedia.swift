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
    
    weak var xmppController: XMPPController!
    
	override func viewDidLoad() {
	
        let darkGreenColor = "009ab5"
        let lightGreenColor = "58cfe4"
                
       	let addBlogEntryButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(addBlogButtonPressed(_:)))
        addBlogEntryButton.tintColor = UIColor(hexString:darkGreenColor)
        self.navigationItem.rightBarButtonItems = [addBlogEntryButton]
        
        
        MangostaSettings().setNavigationBarColor()
        
        self.tableView.backgroundColor = UIColor(hexString:lightGreenColor)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelectionDuringEditing = false

        self.tabBarItem.image = UIImage(named: "Social") // FIXME: no image is appearing
        self.tabBarItem.selectedImage = UIImage(named: "Social Filled") // FIXME: no image is appearing
        
        self.title = "Social"
        
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.xmppController == nil {
            
            self.xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController
            
            self.xmppController.xmppPubSub.addDelegate(self, delegateQueue: dispatch_get_main_queue())
            
        }
       
        self.xmppController?.xmppPubSub.retrieveItemsFromNode(self.xmppController.myMicroblogNode)
        
        self.showHUDwithMessage("Getting MicroBlog list...")
    }

    func addBlogButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController.textFieldAlertController("Create Blog Post", message: "Enter text here") { (blogString) in
            
            self.showHUDwithMessage("Publishing...")
            self.xmppController.xmppPubSub.publishToNode(self.xmppController.myMicroblogNode, entry: DDXMLElement(name: "tittle", stringValue: blogString))
            
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

extension SocialMediaViewController: XMPPPubSubDelegate {
    // TODO: may be not use the following 2
    func xmppPubSub(sender: XMPPPubSub!, didRetrieveSubscriptions iq: XMPPIQ!, forNode node: String!) {
        print("PubSub: Did retrieve subcriptions")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotRetrieveSubscriptions iq: XMPPIQ!) {
        print("PubSub: Did no retrieve subcriptions")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didPublishToNode node: String!, withResult iq: XMPPIQ!) {
        print("PubSub: Did publish to node \(node).")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotPublishToNode node: String!, withError iq: XMPPIQ!) {
        print("PubSub: Did not publish to node \(node) due error: \(iq.childErrorElement())")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didRetrieveItems iq: XMPPIQ!, fromNode node: String!) {
        print("PubSub: Did retrieve items.")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotRetrieveItems iq: XMPPIQ!, fromNode node: String!) {
        print("PubSub: Did not retrieve items due error: \(iq.childErrorElement())")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
}

