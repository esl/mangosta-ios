//
//  Me.swift
//  Mangosta
//
//  Created by Sergio Abraham on 12/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

class Me: UITableViewController, LoginControllerDelegate {
	weak var xmppController: XMPPController!
	
	@IBAction func signOut(sender: AnyObject) {
		AuthenticationModel.remove()
		self.presentLogInView()
		self.xmppController?.disconnect()
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		appDelegate.xmppController = nil
		self.xmppController = nil
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
	func didLogIn() {
		print ("login done")
	}
}