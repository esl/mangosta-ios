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
		
		guard let socialMediaViewController = self.viewControllers?[1] as? SocialMediaViewController else {
			return
		}
		
		// Fixes a nasty problem is the sub storyboard controller's viewDidLoad is not still intantiated.
		
		socialMediaViewController.tabBarItem.title = NSLocalizedString("Social", comment: "")
		socialMediaViewController.tabBarItem.image = UIImage(named: "Social")!
		socialMediaViewController.tabBarItem.selectedImage = UIImage(named: "Social Filled")
		
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
    
    func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
        if let currentNavigationController = self.selectedViewController as? MangostaNavigationController {
       // currentNavigationController.topViewController.
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

