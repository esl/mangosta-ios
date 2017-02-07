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
    
    var blogItems = []
    var refreshControl: UIRefreshControl!
    
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
        
        if self.refreshControl == nil {
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.backgroundColor = UIColor.orangeColor()
           // self.refreshControl?.alpha = 0.4
            self.refreshControl?.tintColor = UIColor.whiteColor()
            
            self.refreshControl?.addTarget(self, action: #selector(refreshListWithPull),
                                           forControlEvents: UIControlEvents.ValueChanged)
            
            self.tableView.addSubview(self.refreshControl)
        }
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.xmppController == nil {
            
            self.xmppController = (UIApplication.sharedApplication().delegate as! AppDelegate).xmppController
            
            self.xmppController.xmppPubSub.addDelegate(self, delegateQueue: dispatch_get_main_queue())
            
        }
        
        self.autoRefreshList()
    }

    func addBlogButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController.textFieldAlertController("Create Blog Post", message: "Enter text here") { (typedString) in
            
            self.showHUDwithMessage("Publishing...")
            if let blogString = typedString {
                self.xmppController.xmppPubSub.publishToNode(self.xmppController.myMicroblogNode, entry: self.creatEntry(blogString))
            }
            else {
                print("No entry typed.")
            }
            
        }
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func creatEntry(blogString: String) -> DDXMLElement {

        let entry = DDXMLElement(name: "entry", xmlns: "http://www.w3.org/2005/Atom")
    
        let titleNode = DDXMLElement(name: "title", stringValue: blogString)
        titleNode.addAttributeWithName("type", stringValue: "text")
        
        let authorName = DDXMLElement(name: "name", stringValue: self.xmppController.xmppStream.myJID.user)
        let authorUri = DDXMLElement(name: "uri", stringValue: "xmpp:"+self.xmppController.xmppStream.myJID.bare())
        let author = DDXMLElement(name: "author")
        author.addChild(authorName)
        author.addChild(authorUri)
        
        entry.addChild(titleNode)
        entry.addChild(author)
        
        return entry
    }
    
    func autoRefreshList() {
        
        self.xmppController?.xmppPubSub.retrieveItemsFromNode(self.xmppController.myMicroblogNode)
        
        self.showHUDwithMessage("Getting MicroBlog list...")
        
    }
    
    func refreshListWithPull() {
        if self.refreshControl != nil {
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            let title = NSString.localizedStringWithFormat(NSLocalizedString("Last update: %@", comment: ""),
                                                           formatter.stringFromDate(NSDate()))
            let attrsDictionary = [ NSForegroundColorAttributeName : UIColor.whiteColor() ]
            let attributedTitle = NSAttributedString(string: title as String, attributes: attrsDictionary)
            self.refreshControl!.attributedTitle = attributedTitle
            
            self.xmppController?.xmppPubSub.retrieveItemsFromNode(self.xmppController.myMicroblogNode)
            
        }
    }
}

extension SocialMediaViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Social Cell") as UITableViewCell!
        
        // TODO: implement when PubSub is working at server side
        
        // cell.textLabel?.text = "No items."
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.blogItems.count == 0 {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            label.text = "No items."
            label.textAlignment = NSTextAlignment.Center
            label.sizeToFit()
            
            self.tableView.backgroundView = label
        }
        return self.blogItems.count
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
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotRetrieveItems iq: XMPPIQ!, fromNode node: String!) {
        print("PubSub: Did not retrieve items due error: \(iq.childErrorElement())")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
}

