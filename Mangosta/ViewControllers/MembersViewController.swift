//
//  MembersViewController.swift
//  Mangosta
//
//  Created by Andres Canal on 5/11/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class MembersViewController: UIViewController {

	var members: [(String, String)]!
	
	@IBOutlet weak var tableView: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
    }

	@IBAction func dismissViewController(sender: AnyObject) {
		self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
	}
}

extension MembersViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.members.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let member = self.members[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier("memberCell")! as UITableViewCell
		
		cell.textLabel!.text = member.1
		cell.detailTextLabel!.text = member.0
		
		return cell
	}
	
}