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
		
	}
}
