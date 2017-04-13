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
		
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGray], for: UIControlState())
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: UIControlState.selected)
        
        XMPPController.sharedInstance.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        XMPPController.sharedInstance.xmppReconnect.addDelegate(self, delegateQueue: DispatchQueue.main)
      
        super.viewDidLoad()
    }
}
extension TabBarController: XMPPStreamDelegate {
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.presentLogInView()
    }
    
    func presentLogInView() {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let loginController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        
        self.present(loginController, animated: true, completion: nil)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        if let currentNavigationController = self.selectedViewController as? MangostaNavigationController {
            if let topViewControllerTittleViewModifiable = currentNavigationController.topViewController as? TitleViewModifiable {
                topViewControllerTittleViewModifiable.resetTitleViewTextToOriginal()
            }
        }
    }
    
}
extension TabBarController: XMPPReconnectDelegate {
    func xmppReconnect(_ sender: XMPPReconnect!, didDetectAccidentalDisconnect connectionFlags: SCNetworkConnectionFlags) {
        if let currentNavigationController = self.selectedViewController as? MangostaNavigationController {
            if (currentNavigationController.topViewController as? TitleViewModifiable) != nil {
                let myTitleView = UILabel()
                myTitleView.text = self.connectingString
                
                currentNavigationController.topViewController?.navigationItem.titleView = myTitleView
                myTitleView.sizeToFit()
            }
        }
    }
}

extension TabBarController {
    
    func handleChatPushNotification(withRemoteJid remoteJid: XMPPJID) {
        let mainViewController = viewControllers!.flatMap { ($0 as? UINavigationController)?.viewControllers[0] as? MainViewController } .first!
        selectedViewController = mainViewController.navigationController
        mainViewController.switchToConversation(withRemoteJid: remoteJid)
    }
}

