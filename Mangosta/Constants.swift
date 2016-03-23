//
//  Constants.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/14/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public typealias VoidCompletion = () -> ()
public typealias BoolCompletion = (success: Bool) -> ()
public typealias RoomListCompletion = (([XMPPRoom]?)->())

public struct Constants {
	public struct Preferences {
		public static let Authentication = "AuthenticationPreferenceName"
	}
}

func delay(delay:Double, closure:()->()) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}