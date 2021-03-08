//
//  InviteController.swift
//  byte
//
//  Created by Xiao Ling on 2/15/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import MessageUI


private let bkColor = Color.primary

class InviteController: UIViewController {
    
    var statusHeight: CGFloat = 20
    var headerHeight: CGFloat = 60
    var tabHeight   : CGFloat = AppFontSize.footer + 20

    var header: AppHeader?
    var left: InviteUserController?
    var right: PhoneBookController?

    var titleLeft: String = ""
    var btnL: TinderTextButton?
    var btnR: TinderTextButton?
    
    var users: [User] = []
    var club: Club?
    
    override func viewDidLoad() {

        super.viewDidLoad()
        view.backgroundColor = bkColor
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
        addGestureResponders()
    }

    func config( with data: [User], for club: Club?, title: String ){
        self.titleLeft = title
        self.users = data
        self.club = club
        placeNavHeader()
        placeTabButtons()
        placeLeft()
        placeRight()
    }

}
    
    
//MARK:- responders

extension InviteController: AppHeaderDelegate, PhoneBookControllerProtocol, MFMessageComposeViewControllerDelegate {
    
    @objc func handleTapLeft(_ button: TinderButton ){
        func fn(){
            self.left?.view.alpha = 1.0
            self.right?.view.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.25 ){
            self.header?.setText(to: self.titleLeft)
        }
    }
        
    @objc func handleTapRight(_ button: TinderButton ){
        func fn(){
            self.left?.view.alpha  = 0.0
            self.right?.view.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){
            self.header?.setText(to: "Invite from contacts")
        }
    }
    
    func onHandleDismiss(){
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
    func didSelect( users: [PhoneContact] ){

        guard let club = club else { return }
        guard let org = ClubList.shared.fetchOrg(for: club) else { return }
        guard let url = UserAuthed.shared.getInstallURL() else { return }

        let numbers = users.map{ $0.get_H2() }
        let code = org.getPhoneNumber(front: false)

        if (MFMessageComposeViewController.canSendText()) {
            DispatchQueue.main.async {
                let controller = MFMessageComposeViewController()
                controller.body = "Download \(APP_NAME) from \(url), and use code \(code) to claim the referral."
                controller.recipients = numbers
                controller.messageComposeDelegate = self
                self.present(controller, animated: true, completion: nil)
            }
        } else {
            heavyImpact()
            ToastSuccess(title: "", body: "You cannot invite guests yet")
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }

}

//MARK:- view

extension InviteController {
    
    func placeLeft(){
        let f = view.frame
        let dy = statusHeight + headerHeight + tabHeight + 20
        let v = InviteUserController()
        v.view.frame = CGRect(x: 0, y: dy, width: f.width, height: f.height-dy)
        v.config(data: self.users, title: "", buttonStr: "Invite", showHeader:false)
        v.view.alpha = 1.0
        view.addSubview(v.view)
        self.left = v
    }
    
    func placeRight(){
        let f = view.frame
        let dy = statusHeight + headerHeight + tabHeight + 20
        let vc = PhoneBookController()
        vc.view.alpha = 0.0
        vc.view.frame = CGRect(x:0,y:dy,width:f.width,height:f.height-dy)
        vc.config( showHeader: false )
        vc.delegate = self
        view.addSubview(vc.view)
        self.right = vc
    }
    
    
    func placeTabButtons(){
        
        let f = view.frame
        let wd = f.width/2 - 20
        let dy = statusHeight + headerHeight + 20
        let font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        
        let bl = TinderTextButton()
        bl.frame = CGRect(x: 10, y: dy, width: wd, height: tabHeight)
        bl.config(with: "MEMBERS", color: Color.primary_dark, font: font)
        bl.backgroundColor = Color.grayQuaternary.lighter(by: 50)
        bl.addTarget(self, action: #selector(handleTapLeft), for: .touchUpInside)
        view.addSubview(bl)
        
        let br = TinderTextButton()
        br.frame = CGRect(x: f.width/2 + 5 , y: dy, width: wd, height: tabHeight)
        br.config(with: "CONTACTS", color: Color.primary_dark, font: font)
        br.backgroundColor = Color.grayQuaternary.lighter(by: 50)
        br.addTarget(self, action: #selector(handleTapRight), for: .touchUpInside)
        view.addSubview(br)
        
        self.btnL = bl
        self.btnR = br
        
    }
    
    func placeNavHeader(){
        let f = view.frame
        let frame = CGRect( x: 0, y: statusHeight, width: f.width, height: headerHeight )
        let h = AppHeader(frame: frame)
        h.config( showSideButtons: true, left: "", right: "xmark", title: self.titleLeft, mode: .light )
        h.delegate = self
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
        self.header = h
    }

    
}



//MARK:- gesture responder

extension InviteController {

    func addGestureResponders(){
        
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .right
        self.view.addGestureRecognizer(swipeRt)
    }

    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                onHandleDismiss()
            default:
                break
            }
        }
    }


}
