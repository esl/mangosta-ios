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

class XMPPRoomMembersListManageAction: ChatViewControllerAdditionalAction, XMPPRoomLightDelegate, MembersViewControllerDelegate {
    
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
    
    func xmppRoomLight(_ sender: XMPPRoomLight, didFailToChangeAffiliations iq: XMPPIQ) {
        sender.fetchMembersList()
    }
    
    func membersViewController(_ controller: MembersViewController, canRemoveMemberAtIndex memberIndex: Int) -> Bool {
        let removedMemberJidString = controller.members[memberIndex].1
        return room.isOwned && removedMemberJidString != room.xmppStream.myJID.bare()
    }
    
    func membersViewController(_ controller: MembersViewController, willRemoveMemberAtIndex memberIndex: Int) -> Bool {
        let removedMemberJidString = controller.members[memberIndex].1
        let memberRemovalAffiliation = DDXMLElement(name: "user", stringValue: removedMemberJidString)
        memberRemovalAffiliation.addAttribute(withName: "affiliation", stringValue: "none")
        room.changeAffiliations([memberRemovalAffiliation])
        return true
    }
    
    func membersViewControllerDidFinish(_ controller: MembersViewController) {
        membersListPresentingViewController.dismiss(animated: true, completion: nil)
        membersListViewController = nil
    }
    
    private func showMembersViewController() {
        let storyboard = UIStoryboard(name: "Members", bundle: nil)
        
        let membersNavController = storyboard.instantiateViewController(withIdentifier: "members") as! UINavigationController
        let membersController = membersNavController.viewControllers.first! as! MembersViewController
        membersController.delegate = self
        membersListPresentingViewController.present(membersNavController, animated: true, completion: nil)
        membersListViewController = membersController
    }
}

private extension XMPPRoomLight {
    
    var isOwned: Bool {
        return knownMembersList().contains { $0.attributeStringValue(forName: "affiliation") == "owner" && $0.stringValue == xmppStream.myJID.bare() }
    }
}
