//
//  Settings.swift
//  Mangosta
//
//  Created by Sergio Abraham on 1/12/17.
//  Copyright © 2017 Inaka. All rights reserved.
//

import Foundation
import UIKit

public struct MangostaSettings {

	public func setNavigationBarColor() {
		UINavigationBar.appearance().backgroundColor = self.colorWithHexString("009ab5")
	}

	func colorWithHexString (hex:String) -> UIColor {
		var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
		
		if (cString.hasPrefix("#")) {
			cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
		}
		
		if ((cString.characters.count) != 6) {
			return UIColor.grayColor()
		}
		
		var rgbValue:UInt32 = 0
		NSScanner(string: cString).scanHexInt(&rgbValue)
		
		return UIColor(
			red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
			green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
			blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
			alpha: CGFloat(1.0)
		)
	}
	
}

class MangostaNavigationController: UINavigationController {
	override func viewDidLoad() {
		super.viewDidLoad()
		MangostaSettings().setNavigationBarColor()
	}
}

//extension UIColor {
//	convenience init(hexString:String) {
//		let hexString:NSString = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
//		let scanner            = NSScanner(string: hexString as String)
//		
//		if (hexString.hasPrefix("#")) {
//			scanner.scanLocation = 1
//		}
//		
//		var color:UInt32 = 0
//		scanner.scanHexInt(&color)
//		
//		let mask = 0x000000FF
//		let r = Int(color >> 16) & mask
//		let g = Int(color >> 8) & mask
//		let b = Int(color) & mask
//		
//		let red   = CGFloat(r) / 255.0
//		let green = CGFloat(g) / 255.0
//		let blue  = CGFloat(b) / 255.0
//		
//		self.init(red:red, green:green, blue:blue, alpha:1)
//	}	
//}
//
//extension UIColor {
//	convenience init(hex: Int) {
//		self.init(hex: hex, a: 1.0)
//	}
//	
//	convenience init(hex: Int, a: CGFloat) {
//		self.init(r: (hex >> 16) & 0xff, g: (hex >> 8) & 0xff, b: hex & 0xff, a: a)
//	}
//	
//	convenience init(r: Int, g: Int, b: Int) {
//		self.init(r: r, g: g, b: b, a: 1.0)
//	}
//	
//	convenience init(r: Int, g: Int, b: Int, a: CGFloat) {
//		self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: a)
//	}
//	
//	convenience init?(hexString: NSString) {
//		guard let hex = hexString else {
//			return nil
//		}
//		self.init(hex: hex)
//	}
//}

