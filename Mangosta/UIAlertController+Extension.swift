//
//  UIAlertController+Extension.swift
//  Mangosta
//
//  Created by Andres Canal on 6/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

extension UIAlertController {
	class func textFieldAlertController(title: String?, message: String?, handler: ((String?) -> Void)) -> UIAlertController {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
		alertController.addTextFieldWithConfigurationHandler(nil)
		alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))

		alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
			guard let userJIDString = alertController.textFields?.first?.text where userJIDString.characters.count > 0 else {
				handler(nil)
				return
			}
			handler(userJIDString)
		}))
		alertController.view.setNeedsLayout()
		return alertController
	}
}