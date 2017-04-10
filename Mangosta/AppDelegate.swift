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
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		print("App Path: \(dirPaths)")

        DDLog.addLogger(DDTTYLogger.sharedInstance(), withLevel:  DDLogLevel.Verbose)
        XMPPController.sharedInstance.pushNotificationsDelegate = self
        XMPPController.sharedInstance.xmppReconnect.manualStart()
        
		return true
	}
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        XMPPController.sharedInstance.enablePushNotificationsWithDeviceToken(deviceToken)
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
        
	}

	func applicationDidEnterBackground(application: UIApplication) {
        XMPPController.sharedInstance.disconnect()
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		XMPPController.sharedInstance.connect()
	}

	func applicationWillTerminate(application: UIApplication) {
		XMPPController.sharedInstance.disconnect()
	}
    

}

extension AppDelegate: XMPPControllerPushNotificationsDelegate {
    
    func xmppControllerDidPrepareForPushNotificationsSupport(controller: XMPPController) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.initializeNotificationServices()
        }
    }
}
