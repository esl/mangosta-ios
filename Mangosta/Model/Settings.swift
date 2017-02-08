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
		UINavigationBar.appearance().backgroundColor = UIColor(hexString:"009ab5")
	}
	
}

class MangostaNavigationController: UINavigationController {
	override func viewDidLoad() {
		super.viewDidLoad()
		MangostaSettings().setNavigationBarColor()
        self.navigationBar.tintColor = UIColor(hexString: "009ab5")
	}
}

// RGB hex String without alpha
extension UIColor {
	convenience init(hexString:String) {
		let hexString:NSString = hexString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		let scanner            = NSScanner(string: hexString as String)
		
		if hexString.hasPrefix("#") {
			scanner.scanLocation = 1
		}
		
		var color:UInt32 = 0
		scanner.scanHexInt(&color)
		
		let mask = 0x000000FF
		let r = Int(color >> 16) & mask
		let g = Int(color >> 8) & mask
		let b = Int(color) & mask
		
		let red   = CGFloat(r) / 255.0
		let green = CGFloat(g) / 255.0
		let blue  = CGFloat(b) / 255.0
		
		self.init(red:red, green:green, blue:blue, alpha:1)
	}
	
	func toHexString() -> String {
		var r:CGFloat = 0
		var g:CGFloat = 0
		var b:CGFloat = 0
		var a:CGFloat = 0
		
		getRed(&r, green: &g, blue: &b, alpha: &a)
		
		let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
		
		return NSString(format:"#%06x", rgb) as String
	}
}
