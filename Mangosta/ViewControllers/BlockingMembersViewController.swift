//
//  UIViewController.swift
//  Mangosta
//
//  Created by Andres Canal on 6/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD

class BlockingMembersViewController: UIViewController, TitleViewModifiable {

	@IBOutlet weak var tableView: UITableView!
	var xmppBlocking: XMPPBlocking?
	var blockingList = [String]()
	weak var xmppController: XMPPController!

    // MARK: titleViewModifiable protocol
    var originalTitleViewText: String? = ""
    func resetTitleViewTextToOriginal() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = originalTitleViewText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.xmppController = XMPPController.sharedInstance
        
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.allowsMultipleSelectionDuringEditing = false

		self.title = self.originalTitleViewText
    }
	
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
            self.resetTitleViewTextToOriginal()
            self.xmppBlocking?.deactivate()
            
            self.xmppBlocking = XMPPBlocking()
            self.xmppBlocking!.autoRetrieveBlockingListItems = true
            self.xmppBlocking!.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppBlocking!.activate(xmppController.xmppStream)
            
        if self.xmppController.xmppStream.isAuthenticated() {
            self.resetTitleViewTextToOriginal()
            self.showHUDwithMessage("Getting blocked list...")
            self.xmppBlocking?.retrieveBlockingListItems()
        }
        else {
            let titleLabel = UILabel()
            titleLabel.text = "Connecting"
            self.navigationItem.titleView = titleLabel
            titleLabel.sizeToFit()
 
        }
    }

	@IBAction func blockMember(_ sender: AnyObject?) {
		let alertController = UIAlertController.textFieldAlertController("Block Member", message: "Enter JID") { (jidString) in
			if let jid = XMPPJID.init(string: jidString) {
				self.showHUDwithMessage("Blocking...")
				self.xmppBlocking?.blockJID(jid)
			}
		}
		self.present(alertController, animated: true, completion: nil)
	}
	
	deinit {
		self.xmppBlocking!.removeDelegate(self)
		self.xmppBlocking!.deactivate()
	}
}

extension BlockingMembersViewController: UITableViewDelegate, UITableViewDataSource {

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as UITableViewCell!
		let blockedJID = self.blockingList[indexPath.row]
		cell?.textLabel?.text = blockedJID
		return cell!
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return blockingList.count
	}
	
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		
		let leave = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Unblock") { (UITableViewRowAction, IndexPath) in
			let blockedJID = self.blockingList[indexPath.row]
			self.showHUDwithMessage("Unblocking...")
			self.xmppBlocking?.unblockJID(XMPPJID.init(string: blockedJID))
		}
		leave.backgroundColor = UIColor.orange
		return [leave]
	}
}

extension BlockingMembersViewController {
	func showHUDwithMessage(_ message: String) {
		let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
		hud?.labelText = message
	}
}

extension BlockingMembersViewController: XMPPBlockingDelegate {
	
	func xmppBlocking(_ sender: XMPPBlocking!, didBlockJID xmppJID: XMPPJID!) {
		self.xmppBlocking?.retrieveBlockingListItems()
		MBProgressHUD.hide(for: self.view, animated: true)
	}
	
	func xmppBlocking(_ sender: XMPPBlocking!, didUnblockJID xmppJID: XMPPJID!) {
		self.xmppBlocking?.retrieveBlockingListItems()
		MBProgressHUD.hide(for: self.view, animated: true)
	}

	func xmppBlocking(_ sender: XMPPBlocking!, didReceivedBlockingList blockingList: [Any]!) {
		self.blockingList = blockingList as! [String]
		self.tableView.reloadData()
		MBProgressHUD.hide(for: self.view, animated: true)
	}
}
