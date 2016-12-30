//
//  TabBarController.swift
//  Mangosta
//
//  Created by Andres Canal on 6/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGrayColor()], forState: UIControlState.Normal)
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Selected)
		
		guard let socialMediaViewController = self.viewControllers?[1] as? SocialMediaViewController else {
			return
		}
		
		// Fixes a nasty problem is the sub storyboard controller's viewDidLoad is not still intantiated. 
		
		socialMediaViewController.tabBarItem.title = NSLocalizedString("Social", comment: "")
		socialMediaViewController.tabBarItem.image = UIImage(named: "Social")!
		socialMediaViewController.tabBarItem.selectedImage = UIImage(named: "Social Filled")
		
	}
}
