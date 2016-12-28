//
//  TabBarController.swift
//  Mangosta
//
//  Created by Andres Canal on 6/30/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

	@IBOutlet weak var thisTabBar: UITabBar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGrayColor()], forState: UIControlState.Normal)
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Selected)

	}
	override func viewWillAppear(animated: Bool) {
		
		self.thisTabBar.items![0].image = UIImage(named: "Social Filled")
		
		self.thisTabBar.items![0].selectedImage = UIImage(named: "Social")
		
		self.thisTabBar.items![1].image = UIImage(named: "Social Filled")
		
		self.thisTabBar.items![1].selectedImage = UIImage(named: "Social")
		
		
		
	}
}
