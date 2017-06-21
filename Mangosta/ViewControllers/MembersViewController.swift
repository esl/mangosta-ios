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
    weak var delegate: MembersViewControllerDelegate?
	
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
        delegate?.membersViewControllerDidFinish(self)
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return delegate?.membersViewController(self, canRemoveMemberAtIndex: indexPath.row) ?? false
    }
	
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let removeMemberAction = UITableViewRowAction(style: .destructive, title: "Remove") { [weak self] (_, indexPath) in
            guard let membersViewController = self else { return }
            if membersViewController.delegate?.membersViewController(membersViewController, willRemoveMemberAtIndex: indexPath.row) == true {
                membersViewController.members.remove(at: indexPath.row)
                membersViewController.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            }
        }
        return [removeMemberAction]
    }
}

protocol MembersViewControllerDelegate: class {
    
    func membersViewController(_ controller: MembersViewController, canRemoveMemberAtIndex memberIndex: Int) -> Bool
    func membersViewController(_ controller: MembersViewController, willRemoveMemberAtIndex memberIndex: Int) -> Bool
    func membersViewControllerDidFinish(_ controller: MembersViewController)
}
