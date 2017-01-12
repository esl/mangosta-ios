//
//  Settings.swift
//  Mangosta
//
//  Created by Sergio Abraham on 1/12/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation
import UIKit

class MangostaSettings: NSObject {
	
	var settingsDictionary : [String:String] = ["darkGrenColor":"009ab5",
	                          "lightGreenColor":"cc58cfe4",
	                          "cellTextLine1Style":"bold",
	                          "cellTextLine2Style":"normal"]
	
	
	class func setNavigationBarColor() {
		UINavigationBar.appearance().backgroundColor = MangostaSettings().colorWithHexString("009ab5")
	}
	
	func colorWithHexString(hexString: String, alpha:CGFloat? = 1.0) -> UIColor {
		
		let hexint = Int(self.intFromHexString(hexString))
		let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
		let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
		let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
		let alpha = alpha!
		
		let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
		return color
	}
	
	func intFromHexString(hexStr: String) -> UInt32 {
		var hexInt: UInt32 = 0
		let scanner: NSScanner = NSScanner(string: hexStr)
		scanner.charactersToBeSkipped = NSCharacterSet(charactersInString: "#")
		scanner.scanHexInt(&hexInt)
		return hexInt
	}
}

class MangostaNavigationController: UINavigationController {
	override func viewDidLoad() {
		super.viewDidLoad()
		MangostaSettings.setNavigationBarColor()
	}
}