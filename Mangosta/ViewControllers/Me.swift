//
//  Me.swift
//  Mangosta
//
//  Created by Sergio Abraham on 12/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

class Me: UITableViewController {
	weak var xmppController: XMPPController!
	
	@IBOutlet weak var accountJID: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.xmppController = XMPPController.sharedInstance
		// TODO: when implementing vCard XEP-0054 add the FN field here
		self.accountJID.text = self.xmppController?.xmppStream.myJID?.bare()
	}
	@IBAction func signOut(sender: AnyObject) {
		
        self.xmppController.disconnect()
        
        AuthenticationModel.remove()
        
        self.presentLogInView()
		#if MangostaREST
			appDelegate.mongooseRESTController = nil
			self.mongooseRESTController = nil
		#endif
	}
	
	func presentLogInView() {
		let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
		let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
		
		self.navigationController?.presentViewController(loginController, animated: true, completion: nil
		)
	}
}
