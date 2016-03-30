//
//  SettingsViewController.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/22/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import XMPPFramework

class SettingsViewController: UIViewController {
	@IBOutlet internal var tableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "Settings"
		
		let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.Done, target: self, action: #selector(close(_:)))
		self.navigationItem.rightBarButtonItem = closeButton
	}
	
	internal func close(sender: AnyObject?) {
		self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
	}
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
	enum SettingsCells: Int {
		case Presence
		case PushNotifications
		case MessageCarbons
		case StreamManagement
		case MessageDeliveryReceipts
		case LastMessageCorrection
		case ClientStateIndication
		case TotalCount
	}
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return SettingsCells.TotalCount.rawValue
	}
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
		
		cell.textLabel?.textColor = UIColor.blackColor()
		var title = ""
		switch indexPath.row {
		case SettingsCells.Presence.rawValue:
			title = "Presence: " + (StreamManager.manager.isOnline() ? "Online" : "Offline")
			cell.textLabel?.textColor = UIColor.blueColor()
		case SettingsCells.PushNotifications.rawValue:
			title = "Push Notifications"
			if !StreamManager.manager.supportsCapability(StreamController.CapabilityTypes.PushNotifications) {
				cell.textLabel?.textColor = UIColor.redColor()
			}
		case SettingsCells.MessageCarbons.rawValue:
			title = "Message Carbons Enabled: " + (StreamManager.manager.messageCarbonsEnabled() ? "Yes" : "No")
			if !StreamManager.manager.supportsCapability(StreamController.CapabilityTypes.MessageCarbons) {
				cell.textLabel?.textColor = UIColor.redColor()
			} else {
				cell.textLabel?.textColor = UIColor.blueColor()
			}
			
		case SettingsCells.StreamManagement.rawValue:
			title = "Stream Management"
			if !StreamManager.manager.supportsCapability(StreamController.CapabilityTypes.StreamManagement) {
				cell.textLabel?.textColor = UIColor.redColor()
			}
		case SettingsCells.MessageDeliveryReceipts.rawValue:
			title = "Message Delivery Receipts"
			if !StreamManager.manager.supportsCapability(StreamController.CapabilityTypes.MessageDeliveryReceipts) {
				cell.textLabel?.textColor = UIColor.redColor()
			}
		case SettingsCells.LastMessageCorrection.rawValue:
			title = "Last Message Correction"
			if !StreamManager.manager.supportsCapability(StreamController.CapabilityTypes.LastMessageCorrection) {
				cell.textLabel?.textColor = UIColor.redColor()
			}
		case SettingsCells.ClientStateIndication.rawValue:
			title = "Client State Indication: " + (StreamManager.manager.isAvailable() ? " Available" : "Unavailable")
			if !StreamManager.manager.supportsCapability(StreamController.CapabilityTypes.ClientStateIndication) {
				cell.textLabel?.textColor = UIColor.redColor()
			}
		default:
			title = "Whoops"
		}
		cell.textLabel?.text = title
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		switch indexPath.row {
		case SettingsCells.Presence.rawValue:
			let online = StreamManager.manager.isOnline()
			StreamManager.manager.sendPresence(!online)
			tableView.reloadData()
		case SettingsCells.PushNotifications.rawValue:
			()
		case SettingsCells.MessageCarbons.rawValue:
			let enabled = StreamManager.manager.messageCarbonsEnabled()
			StreamManager.manager.toggleCarbons(!enabled)
			
			delay(2.0) {
				tableView.reloadData()
			}
			
		case SettingsCells.StreamManagement.rawValue:
			()
		case SettingsCells.MessageDeliveryReceipts.rawValue:
			()
		case SettingsCells.LastMessageCorrection.rawValue:
			()
		case SettingsCells.ClientStateIndication.rawValue:
			let availability = StreamManager.manager.clientState.clientAvailability
			if availability == ClientState.FeatureAvailability.Available {
				StreamManager.manager.becomeUnavailable()
			} else {
				StreamManager.manager.becomeAvailable()
			}
			self.tableView.reloadData()
		default:
			()
		}
	}
}