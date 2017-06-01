//
//  UIAlertController+Extension.swift
//  Mangosta
//
//  Created by Andres Canal on 6/29/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

extension UIAlertController {
	class func textFieldAlertController(_ title: String?, message: String?, handler: @escaping ((String?) -> Void)) -> UIAlertController {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		alertController.addTextField(configurationHandler: nil)
		alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))

		alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) -> Void in
			guard let userJIDString = alertController.textFields?.first?.text, userJIDString.characters.count > 0 else {
				handler(nil)
				return
			}
			handler(userJIDString)
		}))
		alertController.view.setNeedsLayout()
		return alertController
	}
    
    class func singleActionAlertController(withTitle title: String?, message: String?, actionTitle: String = "OK", handler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
        return alertController
    }
}
