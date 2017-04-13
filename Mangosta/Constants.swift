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
public typealias StreamCompletion = ((_ stream: XMPPStream?) -> ())?
public typealias BoolCompletion = (_ success: Bool) -> ()
public typealias RoomListCompletion = ([XMPPRoom]?)->()
public typealias RosterCompletion = ((_ result: Bool, _ roster: XMPPRoster) -> Void)

public struct Constants {
	public struct Preferences {
		public static let Authentication = "AuthenticationPreferenceName"
	}
	
	public struct Notifications {
		public static let StreamControllerWasCreated = "StreamControllerWasCreatedNotificationName"
		public static let RosterWasUpdated = "RosterWasUpdatedNotificationName"
	}
	
	public static func applicationSupportDirectory() -> String {
		let cacheDirectories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		
		return cacheDirectories.first!
	}
}

func delay(_ delay: Double, closure:@escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
