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

        DDLog.add(DDTTYLogger.sharedInstance, with: DDLogLevel.verbose)
        XMPPController.sharedInstance.connect()
        XMPPController.sharedInstance.pushNotificationsDelegate = self
        
		return true
	}
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        XMPPController.sharedInstance.enablePushNotifications(withDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Device token for push notifications: FAIL -- ")
        print(error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // TODO: [pwe] A dedicated payload key for sender's JID delivery
        guard let senderJidString = ((userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary)?["title"] as? String,
            let senderJid = XMPPJID(string: senderJidString) else {
                return
        }
        
        XMPPController.sharedInstance.processPushNotification(from: senderJid)
    }
    
    func initializeNotificationServices() -> Void {
        let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        
        // This is an asynchronous method to retrieve a Device Token
        // Callbacks are in AppDelegate.swift
        // Success = didRegisterForRemoteNotificationsWithDeviceToken
        // Fail = didFailToRegisterForRemoteNotificationsWithError
        UIApplication.shared.registerForRemoteNotifications()
    }

	func applicationWillResignActive(_ application: UIApplication) {
        XMPPController.sharedInstance.goOffLine()
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
        
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
        XMPPController.sharedInstance.goOnline()
        
        // TODO: [pwe] Proper icon badge number management
        application.applicationIconBadgeNumber = 0
	}

	func applicationWillTerminate(_ application: UIApplication) {
		_ = XMPPController.sharedInstance.disconnect()
	}
    

}

extension AppDelegate: XMPPControllerPushNotificationsDelegate {
    
    func xmppControllerDidPrepareForPushNotificationsSupport(_ controller: XMPPController) {
        OperationQueue.main.addOperation {
            self.initializeNotificationServices()
        }
    }
    
    func xmppController(_ controller: XMPPController, didReceivePrivateChatPushNotificationFromContact contact: XMPPUser) {
        OperationQueue.main.addOperation {
            (self.window?.rootViewController as! TabBarController).handlePrivateChatPushNotification(from: contact)
        }
    }
    
    func xmppController(_ controller: XMPPController, didReceiveGroupChatPushNotificationIn room: XMPPRoomLight) {
        OperationQueue.main.addOperation {
            (self.window?.rootViewController as! TabBarController).handleGroupChatPushNotification(in: room)
        }
    }
    
    func xmppController(_ controller: XMPPController, didReceiveChatPushNotificationFromUnknownSenderWithJid senderJid: XMPPJID) {
        // TODO: can a room notification arrive before affiliation message?
        // TODO: handle private chat notifications from senders not on the roster
        NSLog("Received a push notification from an unknown sender: \(senderJid.full())")
    }
}
