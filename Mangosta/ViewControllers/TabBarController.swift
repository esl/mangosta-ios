//
//  TabBarController.swift
//  Mangosta
//
//  Created by Andres Canal on 6/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class TabBarController: UITabBarController {

    let connectingString = "Connecting..."
    
	override func viewDidLoad() {
		
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGrayColor()], forState: UIControlState.Normal)
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Selected)
        
        XMPPController.sharedInstance.xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        XMPPController.sharedInstance.xmppReconnect.addDelegate(self, delegateQueue: dispatch_get_main_queue())
      
        super.viewDidLoad()
    }
}
extension TabBarController: XMPPStreamDelegate {
    func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.presentLogInView()
    }
    
    func presentLogInView() {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        
        self.presentViewController(loginController, animated: true, completion: nil)
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        if let currentNavigationController = self.selectedViewController as? MangostaNavigationController {
            if let topViewControllerTittleViewModifiable = currentNavigationController.topViewController as? titleViewModifiable {
                topViewControllerTittleViewModifiable.resetTitleViewTextToOriginal()
            }
        }
    }
    
}
extension TabBarController: XMPPReconnectDelegate {
    func xmppReconnect(sender: XMPPReconnect!, didDetectAccidentalDisconnect connectionFlags: SCNetworkConnectionFlags) {
        if let currentNavigationController = self.selectedViewController as? MangostaNavigationController {
           let myTitleView = UILabel()
            myTitleView.text = self.connectingString

            currentNavigationController.topViewController?.navigationItem.titleView = myTitleView
            myTitleView.sizeToFit()
        }
    }
}

