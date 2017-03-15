//
//  MUCLightCreateRoomPresenterViewController.swift
//  Mangosta
//
//  Created by Sergio Abraham on 12/6/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation

class MUCLightCreateRoomPresenterViewController: UINavigationController {
	weak var MUCLightDelegate: MUCRoomCreateViewControllerDelegate?
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let createRoomViewController = segue.destination as! MUCRoomCreateViewController
  		createRoomViewController.delegate = MUCLightDelegate
	}
}
