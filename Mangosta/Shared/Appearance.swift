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
		UINavigationBar.appearance().backgroundColor = .mangostaDarkGreen
	}
	
}

class MangostaNavigationController: UINavigationController {
	override func viewDidLoad() {
		super.viewDidLoad()
		MangostaSettings().setNavigationBarColor()
        self.navigationBar.tintColor = .mangostaDarkGreen
	}
}

protocol TitleViewModifiable {
    var originalTitleViewText: String? {
        get
        set
    }
    
    func resetTitleViewTextToOriginal()
}

extension UIColor {
    
    static let mangostaDarkGreen = UIColor(hexString: "009ab5")
    static let mangostaLightGreen = UIColor(hexString: "58cfe4")
    static let mangostaVeryLightGreen = UIColor(red: 0.737, green: 0.933, blue: 0.969, alpha: 1.00)
}

// RGB hex String without alpha
extension UIColor {
	convenience init(hexString:String) {
		let hexString:NSString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString
		let scanner            = Scanner(string: hexString as String)
		
		if hexString.hasPrefix("#") {
			scanner.scanLocation = 1
		}
		
		var color:UInt32 = 0
		scanner.scanHexInt32(&color)
		
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
