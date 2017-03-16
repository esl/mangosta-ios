//
//  AppDelegate.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/11/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework
import CocoaLumberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	#if MangostaREST
	var mongooseRESTController: MongooseAPI!
	#endif
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		print("App Path: \(dirPaths)")

        DDLog.add(DDTTYLogger.sharedInstance(), with:  DDLogLevel.verbose)
        XMPPController.sharedInstance.xmppReconnect.manualStart()
        
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
        
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
        XMPPController.sharedInstance.disconnect()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		_ = XMPPController.sharedInstance.connect()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		_ = XMPPController.sharedInstance.disconnect()
	}


}
