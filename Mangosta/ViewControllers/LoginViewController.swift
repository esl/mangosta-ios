//
//  LoginViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
	@IBOutlet private var jidField: UITextField!
	@IBOutlet private var passwordField: UITextField!
	@IBOutlet private var serverNameField: UITextField!
	var loginDelegate: LoginControllerDelegate?
	
	@IBAction func logIn(sender: AnyObject?) {
		if let serverText = self.serverNameField.text {
			let auth = AuthenticationModel(jidString: self.jidField.text!, serverName: serverText, password: self.passwordField.text!)
			auth.save()
		} else {
			let auth = AuthenticationModel(jidString: self.jidField.text!, password: self.passwordField.text!)
			auth.save()
		}

		self.loginDelegate?.didPressLogInButton()
		self.dismissViewControllerAnimated(true, completion: nil)
	}
    
    // TODO: Deactivated until Landscape rotation is supported.
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
}

protocol LoginControllerDelegate {
	func didPressLogInButton()
}
