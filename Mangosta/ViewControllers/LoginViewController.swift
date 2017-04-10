//
//  LoginViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import MBProgressHUD
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class LoginViewController: UIViewController {
	@IBOutlet fileprivate var jidField: UITextField!
	@IBOutlet fileprivate var passwordField: UITextField!
	@IBOutlet fileprivate var serverNameField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var xmppController: XMPPController!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
	@IBAction func logIn(_ sender: AnyObject?) {
		if let serverText = self.serverNameField.text, self.serverNameField.text?.characters.count > 0 {
			let auth = AuthenticationModel(jidString: self.jidField.text!, serverName: serverText, password: self.passwordField.text!)
			auth.save()
		} else {
			let auth = AuthenticationModel(jidString: self.jidField.text!, password: self.passwordField.text!)
			auth.save()
		}
        

        self.configureAndStartStream()

	}
    
    func configureAndStartStream() {
        
        
        self.xmppController = XMPPController.sharedInstance
        
        self.xmppController.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        // TODO: revert to UIActivityIndicatorView.
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.labelText = "Please wait"
        
        _ = self.xmppController.connect()
        
    }
    
    func showError(_ errorString: String?) {
        if let errorText = errorString {
            self.errorLabel.text = "Error: \(errorText)"
        }
        else {
            self.errorLabel.text = nil
        }
    }

    // TODO: Deactivated until Landscape rotation is supported.
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
}

extension LoginViewController: XMPPStreamDelegate {
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.showError(error.children?.first?.name)
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = nil
        
        let tabBarRootController = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.dismiss(animated: true, completion: {
            appDelegate.window?.rootViewController = tabBarRootController.instantiateInitialViewController()
            appDelegate.window!.makeKeyAndVisible()
        })
        
    }
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
        self.showError(error?.localizedDescription)
        MBProgressHUD.hide(for: self.view, animated: true)
    }
}
