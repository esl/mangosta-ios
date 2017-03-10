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

class SocialMediaViewController: UIViewController, TitleViewModifiable {
    @IBOutlet internal var tableView: UITableView!
    
    weak var xmppController: XMPPController!
    
    var blogItems = [DDXMLElement]()
    var refreshControl: UIRefreshControl!
    
    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String? = "Social"
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }
    
	override func viewDidLoad() {
	
        let darkGreenColor = "009ab5"
        let lightGreenColor = "58cfe4"
        
       	let addBlogEntryButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(addBlogButtonPressed(_:)))
        addBlogEntryButton.tintColor = UIColor(hexString:darkGreenColor)
        self.navigationItem.rightBarButtonItems = [addBlogEntryButton]
        
        self.xmppController = XMPPController.sharedInstance
        self.xmppController.xmppPubSub.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        
        MangostaSettings().setNavigationBarColor()
        
        self.tableView.backgroundColor = UIColor(hexString:lightGreenColor)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelectionDuringEditing = false

        self.tabBarItem.image = UIImage(named: "Social") // FIXME: no image is appearing
        self.tabBarItem.selectedImage = UIImage(named: "Social Filled") // FIXME: no image is appearing
        
        self.title = self.originalTitleViewText
        
        if self.refreshControl == nil {
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.backgroundColor = UIColor.orangeColor()
            self.refreshControl?.tintColor = UIColor.whiteColor()
            
            self.refreshControl?.addTarget(self, action: #selector(refreshListWithPull),
                                           forControlEvents: UIControlEvents.ValueChanged)
            
            self.tableView.addSubview(self.refreshControl)
        }
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.xmppController.xmppStream.isAuthenticated() {
            self.autoRefreshList()
            self.resetTitleViewTextToOriginal()
            
        }
        else {
            let titleLabel = UILabel()
            titleLabel.text = "Connecting"
            self.navigationItem.titleView = titleLabel
            titleLabel.sizeToFit()
        }
    }

    func addBlogButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController.textFieldAlertController("Create Blog Post", message: "Enter text here") { (typedString) in
            
            self.showHUDwithMessage("Publishing...")
            if let blogString = typedString {
                self.xmppController.xmppPubSub.publishToNode(self.xmppController.myMicroblogNode, entry: self.creatEntry(blogString))
            }
            else {
                print("BlogEntry: Nothing typed.")
                MBProgressHUD.hideHUDForView(self.view, animated: true)
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
        
        let now =  NSDate().xmppDateTimeString()
        let published = DDXMLElement(name: "published", stringValue: now)
        let updated = DDXMLElement(name: "updated", stringValue: now)
        entry.addChild(published)
        entry.addChild(updated)
        
        entry.addChild(titleNode)
        entry.addChild(author)
        
        return entry
    }
    
    func autoRefreshList() {
        
        guard self.xmppController.xmppStream.isAuthenticated() else { return }
        
        self.xmppController?.xmppPubSub.retrieveItemsFromNode(self.xmppController.myMicroblogNode)
        
        self.showHUDwithMessage("Getting MicroBlog list...")
        
    }
    
    func refreshListWithPull() {
        guard self.xmppController.xmppStream.isAuthenticated() else { return }
        
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
        
        let entry = self.blogItems[indexPath.row]
        var nodes = [String:String]()
        if let elements = entry.childAtIndex(0) {
            for i in 0...elements.childCount - 1 {
                if let element = elements.childAtIndex(i) as? DDXMLElement {
                    guard let key = element.name else {
                        continue
                    }
                    let value : String
                    if element.children != nil {
                        value = (element.childAtIndex(0)?.stringValue)!
                    }
                    else {
                        value = element.stringValue!
                    }
                    nodes[key] = value
                }
            }
        }
        
        cell.textLabel?.text = nodes["title"]
        if let published = nodes["published"], let author = nodes["author"] {
            let date = NSDate(xmppDateTimeString: published)
            cell.detailTextLabel?.text = "\(author) published on \(date)."
        }
        
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
        else {
            self.tableView.backgroundView = nil
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
        self.autoRefreshList()
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotPublishToNode node: String!, withError iq: XMPPIQ!) {
        print("PubSub: Did not publish to node \(node) due error: \(iq.childErrorElement())")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didRetrieveItems iq: XMPPIQ!, fromNode node: String!) {
        print("PubSub: Did retrieve items.")
        if let pubsub = iq.elementForName("pubsub", xmlns: "http://jabber.org/protocol/pubsub") {
            if  let items = pubsub.elementForName("items")?.elementsForName("item") {
                self.blogItems = items
            }
        }
        
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    func xmppPubSub(sender: XMPPPubSub!, didNotRetrieveItems iq: XMPPIQ!, fromNode node: String!) {
        print("PubSub: Did not retrieve items due error: \(iq.childErrorElement())")
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
}

