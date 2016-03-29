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
public typealias StreamCompletion = (stream: XMPPStream?) -> ()
public typealias BoolCompletion = (success: Bool) -> ()
public typealias RoomListCompletion = ([XMPPRoom]?)->()
public typealias RosterCompletion = ((result: Bool, roster: XMPPRoster) -> Void)

public struct Constants {
	public struct Preferences {
		public static let Authentication = "AuthenticationPreferenceName"
	}
	
	public struct Notifications {
		public static let StreamControllerWasCreated = "StreamControllerWasCreatedNotificationName"
		public static let RosterWasUpdated = "RosterWasUpdatedNotificationName"
	}
	
	public static func applicationSupportDirectory() -> String {
		let cacheDirectories = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		
		return cacheDirectories.first!
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