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
    
    // TODO: [pwe] proper model
    struct Model {
        private(set) var orderedBlogItems = [DDXMLElement]()
        private(set) var publisherIndex = [XMPPJID: DDXMLElement]()
        
        mutating func insertBlogItem(_ blogItem: DDXMLElement, fromPublisher publisherJid: XMPPJID) -> Bool {
            let previousItemDate = publisherIndex[publisherJid]?.microblogEntryUpdatedDate() ?? .distantPast
            guard previousItemDate < blogItem.microblogEntryUpdatedDate() else {
                return false
            }
            
            publisherIndex[publisherJid] = blogItem
            orderedBlogItems = publisherIndex.values.sorted { $0.microblogEntryUpdatedDate() > $1.microblogEntryUpdatedDate() }
            
            return true
        }
    }
    
    @IBOutlet internal var tableView: UITableView!
    
    weak var xmppController: XMPPController!
    
    var model = Model()
    var pendingPublishRequestID: String?
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String? = "Social"
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }
    
	override func viewDidLoad() {
	
        let darkGreenColor = "009ab5"
        let lightGreenColor = "58cfe4"
        
       	let addBlogEntryButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addBlogButtonPressed(_:)))
        addBlogEntryButton.tintColor = UIColor(hexString:darkGreenColor)
        self.navigationItem.rightBarButtonItems = [addBlogEntryButton]
        
        self.xmppController = XMPPController.sharedInstance
        self.xmppController.microbloggingDelegate = self
        
        MangostaSettings().setNavigationBarColor()
        
        self.tableView.backgroundColor = UIColor(hexString:lightGreenColor)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tableView.estimatedRowHeight = 44

        self.tabBarItem.image = UIImage(named: "Social") // FIXME: no image is appearing
        self.tabBarItem.selectedImage = UIImage(named: "Social Filled") // FIXME: no image is appearing
        
        self.title = self.originalTitleViewText
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.xmppController.xmppStream.isAuthenticated() {
            self.resetTitleViewTextToOriginal()
            
        }
        else {
            let titleLabel = UILabel()
            titleLabel.text = "Connecting"
            self.navigationItem.titleView = titleLabel
            titleLabel.sizeToFit()
        }
    }

    func addBlogButtonPressed(_ sender: AnyObject) {
        let alertController = UIAlertController.textFieldAlertController("Create Blog Post", message: "Enter text here") { (typedString) in
            
            self.showHUDwithMessage("Publishing...")
            if let blogString = typedString {
                self.pendingPublishRequestID = self.xmppController.publishMicroblogEntry(withTitle: blogString)
            }
            else {
                print("BlogEntry: Nothing typed.")
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            
        }
        self.present(alertController, animated: true, completion: nil)
    }
}

extension SocialMediaViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Social Cell", for: indexPath)
        let entry = model.orderedBlogItems[indexPath.row]

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = entry.microblogEntryTitle()
        if let publishedDate = entry.microblogEntryPublishedDate(), let author = entry.microblogEntryAuthorName() {
            cell.detailTextLabel?.text = "\(author) published on \(dateFormatter.string(from: publishedDate))."
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if model.orderedBlogItems.isEmpty {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            label.text = "No items."
            label.textAlignment = NSTextAlignment.center
            label.sizeToFit()
            
            self.tableView.backgroundView = label
        }
        else {
            self.tableView.backgroundView = nil
        }
        return model.orderedBlogItems.count
    }
}

extension SocialMediaViewController {
    func showHUDwithMessage(_ message: String) {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.labelText = message
    }
}

extension SocialMediaViewController: XMPPControllerMicrobloggingDelegate {
    
    func xmppController(_ controller: XMPPController, didPublishMicroblogEntryWithRequestID requestID: String) {
        guard requestID == pendingPublishRequestID else {
            return
        }
        
        MBProgressHUD.hide(for: self.view, animated: true)
        pendingPublishRequestID = nil
    }
    
    func xmppController(_ controller: XMPPController, didFailToPublishMicroblogEntryWithRequestID requestID: String) {
        guard requestID == pendingPublishRequestID else {
            return
        }
        
        MBProgressHUD.hide(for: self.view, animated: true)
        pendingPublishRequestID = nil

        present(UIAlertController.singleActionAlertController(withTitle: nil, message: "Failed to publish"), animated: true)
    }
    
    func xmppController(_ controller: XMPPController, didReceiveMicroblogEntries microblogEntries: [DDXMLElement], from publisherJID: XMPPJID) {
        var areNewEntriesInserted = false
        for item in microblogEntries {
            if model.insertBlogItem(item, fromPublisher: publisherJID) {
                areNewEntriesInserted = true
            }
        }
        
        if areNewEntriesInserted {
            tableView.reloadData()
        }
    }
}
