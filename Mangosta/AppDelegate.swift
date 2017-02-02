//
//  AppDelegate.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/11/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var xmppController: XMPPController!
	#if MangostaREST
	var mongooseRESTController: MongooseAPI!
	#endif
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		print("App Path: \(dirPaths)")
        initializeNotificationServices()

		return true
	}
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceTokenStr = UnsafeBufferPointer<UInt8>(start: UnsafePointer(deviceToken.bytes),
            count: deviceToken.length).map { String(format: "%02x", $0) }.joinWithSeparator("")
        print("DeviceId: \(deviceTokenStr)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Device token for push notifications: FAIL -- ")
        print(error.description)
    }
    
    func initializeNotificationServices() -> Void {
        let settings = UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        // This is an asynchronous method to retrieve a Device Token
        // Callbacks are in AppDelegate.swift
        // Success = didRegisterForRemoteNotificationsWithDeviceToken
        // Fail = didFailToRegisterForRemoteNotificationsWithError
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }

	func applicationWillResignActive(application: UIApplication) {
		self.xmppController?.setXEP0352(false)
	}

	func applicationDidEnterBackground(application: UIApplication) {
		
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		self.xmppController?.setXEP0352(true)
	}

	func applicationWillTerminate(application: UIApplication) {
		self.xmppController?.setXEP0352(false)
	}


}
