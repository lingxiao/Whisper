//
//  Home+Events.swift
//  byte
//
//  Created by Xiao Ling on 2/27/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit



//MARK:- USER GEN EVENTS

extension HomeController : OrgCellDelegate {
    
    // @Use: on tap the org, reload the home page to be that of the org
    func ontap( org: OrgModel? ){
        guard let org = org else { return }
        let feed = ClubList.shared.fetchNewsFeed().filter{ $0.0.uuid == org.uuid }
        if feed.count == 0 { return }
        layoutViews(with: feed[0], offset: true)
        self.onSwipeLeft()
        let lives = ClubList.shared.whereAmILive()
        if lives.count > 0 {
            showActiveView(on: lives[0])
        }
    }
}


extension HomeController : NumberPadControllerDelegate, ClubHomeDirCellDelegate {
    
    func onHandleHideNumberPad( with club: Club? ){
        return;
    }
    
    func onTapHomeClub( at club: Club? ){
        showClub(at: club)
    }

    func onTapIcon( at club: Club? ){
        return
    }
    
    func onTap(user:User?){
        return
    }
    
    private func hideNewClubView(){
        func fn(){ self.newClubView?.alpha = 0.0 }
        runAnimation( with: fn, for: 0.25 ){
            self.newClubView?.removeFromSuperview()
            self.newClubView = nil
        }
    }
}


//MARK:- ACIVE CLUB TOAST

extension HomeController: ResumeViewDelegate {
    
    func showActiveView( on club: Club? ){
        hideActiveView()
        let f = view.frame
        let dy = f.height - 2*footerHeight
        let v = ResumeView(frame: CGRect(x: 0, y: dy, width: f.width, height: footerHeight))
        v.config(with: club)
        v.delegate = self
        newsFeed?.view.addSubview(v)
        self.resumeView = v
    }
    
    func hideActiveView(){
        self.resumeView?.removeFromSuperview()
        self.resumeView = nil
    }
    
    func onTapResumeView(from club: Club?) {
        showClub(at: club)
    }
}

//MARK:- CLUB

extension HomeController: ClubDirectoryDelegate, PhoneNumberViewDelegate {

    func showClub( at club: Club? ){
        heavyImpact()
        if let club = club {
            showActiveView(on: club)
            goShowClub( at: club )
        } else {
            ToastSuccess(title: "Oh no", body: "We can't find this channel right now")
        }
    }

    private func goShowClub(at club: Club){
        
        if club.isVisibleToMe(){
            let vc = AudioRoomParentController()
            vc.view.frame = UIScreen.main.bounds
            vc.config(with: club)
            AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
            self.showActiveView(on: club)
        } else {
            ToastSuccess(title: "Oh no!", body: "This channel is locked")
        }
    }
    
    
    // show modal that create new channels
    func onCreateNewRoom(from org: OrgModel? ){

        guard let org = org else { return }

        newCohortView?.removeFromSuperview()
        darkView?.removeFromSuperview()
        self.newCohortView = nil

        let f  = view.frame
        let ht = NewRoomModal.height()
        let dy = (f.height - ht)/2 - 10

        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnDarkView))
        v.addGestureRecognizer(g1)
        self.darkView = v

        let card = NewRoomModal()
        card.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: ht)
        card.config( at: org, width: f.width-20 )
        card.delegate = self
        card.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 15)
        view.addSubview(card)
        view.bringSubviewToFront(card)
        self.newCohortView = card
        func fn(){
            self.newCohortView?.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.darkView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }

    }
    
       
    // share number of htis channel
    func shareNumber(from org: OrgModel?){
        
        heavyImpact()

        let clubs = ClubList.shared.fetchClubsFor(school: org).filter{ $0.type == .home }
        if clubs.count == 0 { return }
        let club = clubs[0]
        
        self.phoneNumberView?.removeFromSuperview()
        self.darkView?.removeFromSuperview()
        self.phoneNumberView = nil
        self.darkView = nil
        
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnBlurViewFromPhoneNumberView))
        v.addGestureRecognizer(g1)
        self.darkView = v
        
        let f = view.frame
        let ht = PhoneNumberView.Height( with: club, width: f.width - 20, short: true )
        let dy = (f.height - ht)/2
        let card = PhoneNumberView(frame:CGRect(x: 10, y: f.height, width: f.width-20, height: ht))
        card.config(with: club, short:true)
        card.delegate = self
        card.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)
        view.addSubview(card)
        view.bringSubviewToFront(card)
        self.phoneNumberView = card
        
        func fn(){
            self.phoneNumberView?.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.darkView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }

    }
    
    func onDismissPhoneNumberView() {
        let f = view.frame
        func fn(){ self.phoneNumberView?.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60) }
        runAnimation( with: fn, for: 0.25 ){
            self.phoneNumberView?.removeFromSuperview()
            self.phoneNumberView = nil
            self.darkView?.removeFromSuperview()
            self.darkView = nil
        }
    }

    
    @objc func onTapOnBlurViewFromPhoneNumberView(sender : UITapGestureRecognizer){
        onDismissPhoneNumberView()
    }

    
    // on tap background view, hide modal
    @objc func onTapOnDarkView(sender : UITapGestureRecognizer){
        hideNewRoomModal()
    }
    
    private func hideNewRoomModal(){
        let f = view.frame
        func fn(){
            self.newCohortView?.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.newCohortView?.removeFromSuperview()
            self.newCohortView = nil
            self.darkView?.removeFromSuperview()
            self.darkView = nil
        }
    }
}

//MARK:- NEW MODAL

extension HomeController : NewRoomModalDelegate {
    
    func onCancel( at org: OrgModel? ){
        hideNewRoomModal()
    }
    
    func onMkOpen( at org: OrgModel? ){
        mkRoomAndOpenRoom(at: org, type: .cohort)
    }
    
    func onMkOneTime( at org: OrgModel? ){
        mkRoomAndOpenRoom(at: org, type: .ephemeral)
    }
    
    
    private func mkRoomAndOpenRoom( at org: OrgModel?, type: ClubType ){
        
        // change view
        hideNewRoomModal()
        if self.isCreatingRoom { return }
        guard let org = org else { return }
        self.isCreatingRoom = true
        placeIndicator("Creating room")

        // make club and go to it
        let title = "\(UserAuthed.shared.get_H1())'s room"
        Club.create(name: title, orgID: org.uuid, type: type, locked:false ){ cid in
        
            guard let cid = cid else {
                self.hideIndicator()
                return ToastSuccess(title: "Ops", body: "Network error")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                self?.isCreatingRoom = false
                self?.hideIndicator()
                ClubList.shared.getClub(at: cid){ club in
                    postRefreshClubPage(at:"ALL")
                    self?.showClub(at: club)
                }
            }
        }
    }
}



//MARK:- FOOTER

// @use: on tapp buttons on footer, tab between different views
extension HomeController : HomeFooterDelegate {
    
    func onTapHome(){
        heavyImpact()
        func fn(){
            self.newsFeed?.view.alpha  = 1.0
            self.alertFeed?.view.alpha = 0.0
            self.padView?.view.alpha   = 0.0
            self.profileVw?.view.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.05 ){
            self.alertFeed?.view.removeFromSuperview()
            self.padView?.view.removeFromSuperview()
            self.profileVw?.view.removeFromSuperview()
            self.alertFeed = nil
            self.padView = nil
            self.profileVw = nil
        }
    }

    func onTapAlerts() {
        heavyImpact()
        if self.alertFeed == nil {
            let f = view.frame
            let vc = AlertController()
            vc.view.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height-footerHeight)
            vc.config( isHome: false )
            self.alertFeed = vc
            view.addSubview(vc.view)
            vc.view.alpha = 0.0
        }
        func fn(){
            self.newsFeed?.view.alpha  = 0.0
            self.alertFeed?.view.alpha = 1.0
            self.padView?.view.alpha   = 0.0
            self.profileVw?.view.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.05 ){
            self.padView?.view.removeFromSuperview()
            self.profileVw?.view.removeFromSuperview()
            self.padView = nil
            self.profileVw = nil
        }
    }
    
    /*
     @use: create new group, drawing from groups i admin
    */
    func onTapNew(){
        heavyImpact()
        if self.padView == nil {
            let f = view.frame
            let vc = NumberPadController()
            vc.view.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height-footerHeight)
            vc.config( with: "Join channel", showHeader: true, isHome: true)
            vc.delegate = self
            self.padView = vc
            view.addSubview(vc.view)
            vc.view.alpha = 0.0
        }
        func fn(){
            self.newsFeed?.view.alpha = 0.0
            self.alertFeed?.view.alpha = 0.0
            self.padView?.view.alpha = 1.0
            self.profileVw?.view.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.05 ){
            self.alertFeed?.view.removeFromSuperview()
            self.profileVw?.view.removeFromSuperview()
            self.alertFeed = nil
            self.profileVw = nil
        }
    }
    
    
    func onTapProfile() {
        heavyImpact()
        if self.profileVw == nil {
            let f = view.frame
            let vc = ProfileController()
            vc.view.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height-footerHeight)
            vc.config( with: UserList.shared.yieldMyself(), isHome: true )
            self.profileVw = vc
            view.addSubview(vc.view)
            vc.view.alpha = 0.0
        }
        func fn(){
            self.newsFeed?.view.alpha = 0.0
            self.alertFeed?.view.alpha = 0.0
            self.padView?.view.alpha = 0.0
            self.profileVw?.view.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.05 ){
            self.alertFeed?.view.removeFromSuperview()
            self.padView?.view.removeFromSuperview()
            self.alertFeed = nil
            self.padView = nil
        }
    }

}
