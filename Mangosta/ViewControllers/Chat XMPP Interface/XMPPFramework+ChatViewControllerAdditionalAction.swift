//
//  XMPPFramework+ChatViewControllerAdditionalAction.swift
//  Mangosta
//
//  Created by Piotr Wegrzynek on 01/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

import XMPPFramework

// TODO: [pwe] history should be fetched in batches as the user scrolls to the top
// TODO: [pwe] avoiding refetching messages that are already present in the local store
class XMPPOneToOneChatMessageHistoryFetchAction: ChatViewControllerAdditionalAction {
    
    var label: String { return "Retrieve conversation history" }
    private let xmppController: XMPPController
    private let userJid: XMPPJID
    
    init(xmppController: XMPPController, userJid: XMPPJID) {
        self.xmppController = xmppController
        self.userJid = userJid
    }
    
    func perform(inContextOf chatViewController: ChatViewController) {
        xmppController.retrieveMessageHistory(filteredBy: userJid)
    }
}

class XMPPRoomChatMessageHistoryFetchAction: ChatViewControllerAdditionalAction {
    
    var label: String { return "Retrieve conversation history" }
    private let xmppController: XMPPController
    private let roomJid: XMPPJID
    
    init(xmppController: XMPPController, roomJid: XMPPJID) {
        self.xmppController = xmppController
        self.roomJid = roomJid
    }
    
    func perform(inContextOf chatViewController: ChatViewController) {
        xmppController.retrieveMessageHistory(fromArchiveAt: roomJid)
    }
}

class XMPPRoomMemberInviteAction: ChatViewControllerAdditionalAction {
    
    var label: String { return "Invite member" }
    private let room: XMPPRoomLight
    
    init(room: XMPPRoomLight) {
        self.room = room
    }
    
    func perform(inContextOf chatViewController: ChatViewController) {
        let alertController = UIAlertController.textFieldAlertController("Add member", message: "Enter the JID") { (jidString) in
            guard let userJIDString = jidString, let userJID = XMPPJID.init(string: userJIDString) else { return }
            self.room.addUsers([userJID])
        }
        chatViewController.present(alertController, animated: true, completion: nil)
    }
}

class XMPPRoomSubjectChangeAction: ChatViewControllerAdditionalAction {
    
    var label: String { return "Change subject" }
    private let room: XMPPRoomLight
    
    init(room: XMPPRoomLight) {
        self.room = room
    }
    
    func perform(inContextOf chatViewController: ChatViewController) {
        let alertController = UIAlertController.textFieldAlertController("Subject", message: nil) { (subjectText) in
            if let text = subjectText {
                self.room.changeRoomSubject(text)
            }
        }
        chatViewController.present(alertController, animated: true, completion: nil)
    }
}

class XMPPRoomMembersListDisplayAction: ChatViewControllerAdditionalAction, XMPPRoomLightDelegate {
    
    var label: String { return "View members list" }
    private let room: XMPPRoomLight
    private var membersListPresentingViewController: UIViewController!
    private var membersListViewController: MembersViewController?
    
    init(room: XMPPRoomLight) {
        self.room = room
        room.addDelegate(self, delegateQueue: .main)
    }
    
    func perform(inContextOf chatViewController: ChatViewController) {
        membersListPresentingViewController = chatViewController
        showMembersViewController()
        room.fetchMembersList()
    }
    
    func xmppRoomLight(_ sender: XMPPRoomLight, didFetchMembersList iqResult: XMPPIQ) {
        membersListViewController?.configure(with: sender.knownMembersList().map { (child) -> (String, String) in
            return (child.attribute(forName: "affiliation")!.stringValue!, child.stringValue!)
        })
    }
    
    private func showMembersViewController() {
        let storyboard = UIStoryboard(name: "Members", bundle: nil)
        
        let membersNavController = storyboard.instantiateViewController(withIdentifier: "members") as! UINavigationController
        let membersController = membersNavController.viewControllers.first! as! MembersViewController
        membersListPresentingViewController.present(membersNavController, animated: true, completion: nil)
        membersListViewController = membersController
    }
}
