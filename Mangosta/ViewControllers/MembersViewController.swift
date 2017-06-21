//
//  MembersViewController.swift
//  Mangosta
//
//  Created by Andres Canal on 5/11/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class MembersViewController: UIViewController {

    fileprivate(set) var members = [(affiliation: String, jidString: String)]()
	
	@IBOutlet weak var tableView: UITableView!
	
    func configure(with members: [(affiliation: String, jidString: String)]) {
        self.members = members
        tableView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
    }

	@IBAction func dismissViewController(_ sender: AnyObject) {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
}

extension MembersViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.members.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let member = self.members[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell")! as UITableViewCell
		
		cell.textLabel!.text = member.1
		cell.detailTextLabel!.text = member.0
		
		return cell
	}
	
}
