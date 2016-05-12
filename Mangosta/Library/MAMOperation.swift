//
//  MAMOperation.swift
//  Mangosta
//
//  Created by Andres Canal on 5/12/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class MAMOperation: AsyncOperation {
	var mainOperation: (() -> ())?
	var boolCompletion: ((result: Bool) -> ())?
	
	var room: XMPPMessageArchiveManagement?

	class func retrieveHistory() -> MAMOperation {
	
		return MAMOperation()
	}

	internal func finishAndRemoveDelegates() {
		
		finish()
	}
}
