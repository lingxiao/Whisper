//
//  AudioRoom+Events.swift
//  byte
//
//  Created by Xiao Ling on 12/7/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import AVFoundation
import Social


//MARK:- GRID EVENTS

extension AudioRoomController : RoomGridControllerDelegate {    
    
    // show options modal
    func onTapUser(at user: User?) {
        let f = view.frame
        let ratio = AudioRoomModal.height( self.club, user )/f.height
        let attributes = centerToastFactory(ratio: ratio, displayDuration: 100000)
        let modal = AudioRoomModal()
        modal.delegate = self
        modal.config( with: club, at: self.room, for: user, width: f.width-20)
        SwiftEntryKit.display(entry: modal, using: attributes)
    }

    // on tap header, show club
    func onTapHeader( for club: Club?, at room: Room? ){
        let v = EditClubController()
        v.view.frame = UIScreen.main.bounds
        v.config(with: self.club, room: self.room)
        AuthDelegate.shared.home?.navigationController?.pushViewController(v, animated: true)
    }
    
    func didRefreshGrid(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.maybeLayoutAnalyticsBtn()
            self?.maybeLayoutChatBtn()
        }
    }
}

//MARK:- GRID PROFILE EVENTS

extension AudioRoomController : AudioRoomModalDelegate {

    // @Use: Follow user, when it go live notify me, let the other person know
    // you want to alerted by what he/she says.
    func onHandleAlertMe(with club: Club, at room: Room?, for user: User) {
        ToastSuccess(title: "Done!", body: "Alert preference saved")
        UserAuthed.shared.follow(user)
        setAlert(for: user.uuid, kind: .alertMe)
    }

    func onHandleRemove(with club: Club, at room: Room?, for user: User) {

        SwiftEntryKit.dismiss()

        let bod = "\(user.get_H1()) can still enter this room after the expulsion"
        let optionMenu = UIAlertController(title: "Remove \(user.get_H1())", message: bod, preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: "Yes"   , style: .default, handler: {a in
            if club.iamAdmin() {
                room?.expel(this: user)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel"   , style: .cancel )
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
        
    }
    
    func onHandleGoToProfile(to user: User) {
        SwiftEntryKit.dismiss()
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    // sit down/raise hand/get on stage
    func onSitDown( for user: User? ){

        SwiftEntryKit.dismiss()

        guard let room = room else { return }
        guard let club = club else { return }
        
        if let record = room.getMember(user?.uuid){

            if record.state == .speaking {

                room.sitDown(this: user)

            } else if record.state == .podding {

                return
                
            } else if club.iamAdmin() || club.iCanSpeakInRooms() {

                room.standUp(this:user)

            } else {
                room.raiseHand()
            }
        }
    }
    
    
    // invite user to a group of mine
    func onAddToGroup( for user: User? ){

        SwiftEntryKit.dismiss()

        let f = view.frame
        let ratio = InviteGroupModal.height()/f.height
        let attributes = centerToastFactory(ratio: ratio, displayDuration: 100000)
        let modal = InviteGroupModal()
        modal.delegate = self
        modal.config( for: user, width: f.width-20)
        SwiftEntryKit.display(entry: modal, using: attributes)

    }
}

extension AudioRoomController: RoomHeaderCellDelegate {
    
    func handleTapRoomHeader(on club: Club?, from room: Room?, with user: User?) {
        ToastSuccess(title: "Invite sent!", body: "")
        setAlert(for: user?.uuid, kind: .inviteToGroup, meta: club?.uuid ?? "")
    }

}



//MARK:- ADMIN VIEW event

// admin view
extension AudioRoomController : AnalyticsControllerDelegate, ChatButtonDelegate, ChatRoomDelegate {

    func didTap( on btn: ChatButton ){

        self.blurView?.removeFromSuperview()
        self.statView?.view.removeFromSuperview()
        self.chatRoom?.view.removeFromSuperview()
        self.chatRoom = nil
        
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        self.blurView = v
        
        let f = view.frame
        let vc = ChatRoom()
        let dy = statusHeight + 20
        vc.view.frame = CGRect(x:0, y: f.height, width: f.width, height: f.height - dy)
        vc.config(with: self.club, at: self.room)
        vc.delegate = self
        self.chatRoom = vc
        let _ = vc.view.roundCorners(corners: [.topLeft,.topRight], radius: 20)
        view.addSubview(vc.view)
        
        func fn(){
            v.alpha = 1.0
            vc.view.frame = CGRect(x:0, y: dy, width: f.width, height: f.height - dy)
        }
        runAnimation( with: fn, for: 0.35 ){ return }

    }

    func onDismiss(this vc: ChatRoom) {

        let f = view.frame
        let dy = statusHeight + 20

        func fn(){
            self.blurView?.alpha = 0.0
            vc.view.frame = CGRect(x:0, y: f.height, width: f.width, height: f.height - dy)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.blurView?.removeFromSuperview()
            vc.view.removeFromSuperview()
            self.blurView = nil
            self.statView = nil
        }
    }
    
    
    @objc func handleTapAnalytics(_ button: TinderButton ){
        
        self.blurView?.removeFromSuperview()
        self.chatRoom?.view.removeFromSuperview()
        self.chatRoom = nil
        
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        self.blurView = v
        
        let f = view.frame
        let vc = AnalyticsController()
        let dy = statusHeight + 20
        vc.view.frame = CGRect(x:0, y: f.height, width: f.width, height: f.height - dy)
        vc.config(with: self.club, at: self.room)
        vc.delegate = self
        self.statView = vc
        let _ = vc.view.roundCorners(corners: [.topLeft,.topRight], radius: 20)
        view.addSubview(vc.view)
        
        func fn(){
            v.alpha = 1.0
            vc.view.frame = CGRect(x:0, y: dy, width: f.width, height: f.height - dy)
        }
        runAnimation( with: fn, for: 0.35 ){ return }

    }
    
    func onHandleHideAnalyticsController( at vc: AnalyticsController ){

        let f = view.frame
        let dy = statusHeight + 20

        func fn(){
            self.blurView?.alpha = 0.0
            vc.view.frame = CGRect(x:0, y: f.height, width: f.width, height: f.height - dy)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.blurView?.removeFromSuperview()
            vc.view.removeFromSuperview()
            self.blurView = nil
            self.statView = nil
        }
    }

    
}

//MARK:- FOOTER event

extension AudioRoomController : AudioButtonStackDelegate {

    // @Use: leave channnel
    func didTapLive() {
        
        SwiftEntryKit.dismiss()

        // check out of all decks
        //FlashCardCache.shared.checkOutOfAllDeck(from:self.club)
        
        guard let room = room else {
            onHandleDismiss()
            return
        }

        if room.iamHere() == false {
            onHandleDismiss()
            return
        }
        
        guard let club = room.club else {
            exitLive(){ return }
            onHandleDismiss()
            return
        }
        
        if let player = club.getCurrentPod()?.pod.player {
            self.avPlayerActive = false
            player.pause()
        }
        
        exitLive(){ return }
        postRefreshClubPage( at: self.club?.uuid ?? "")
        onHandleDismiss()
    }
    
    func didTapShare(){
        heavyImpact()
        guard let club = club else {
            return ToastSuccess(title: "", body: "No data found")
        }
        
        self.phoneNumberView?.removeFromSuperview()
        self.phoneNumberView = nil
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnBlurViewFromPhoneNumberView))
        v.addGestureRecognizer(g1)
        self.blurView = v
        
        let f = view.frame
        let ht = PhoneNumberView.Height(with: club, width: f.width-20, short: false)
        let dy = (f.height - ht)/2
        let card = PhoneNumberView(frame:CGRect(x: 10, y: f.height, width: f.width-20, height: ht))
        card.config(with: club )
        card.delegate = self
        card.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)
        view.addSubview(card)
        view.bringSubviewToFront(card)
        self.phoneNumberView = card
        
        func fn(){
            self.phoneNumberView?.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.blurView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }
    }
        
    // stop the current player if going, else raise hand or toggle mute
    func didTapMute() {
        
        if self.avPlayerActive {

            if let player = club?.getCurrentPod()?.pod.player  {
                player.pause()
            }
            room?.setPodding(to: false){ return }

            stack?.setMute(muted: true)
            //setSideBarPlay(false)
            self.avPlayerActive = false
            
            if AgoraClient.shared.inChannel() == false {
                goLive(autoAlert: false)
            }
                        
        } else {
            
            goMuteOrRaiseHand()
        
        }
    }
    
    private func goMuteOrRaiseHand(){

        if let record = room?.getMyRecord(){
            
            if record.state == .speaking {
                room?.maybeMute()
            } else if record.state == .podding {
                room?.setPodding(to: false){ return }
            } else {
                if let club = club {
                    if club.iCanSpeakInRooms() {
                        let me = UserList.shared.yieldMyself()
                        room?.standUp(this: me)
                    } else {
                        room?.raiseHand()
                    }
                } else {
                    room?.raiseHand()
                }
            }
        }
    }
    
        
    func didTapInvite(){

        guard let club = club else { return }
        guard let room = room else { return }
        guard let org = club.getOrg() else { return }
        
        var users : [User] = room.inClubButNotInRoom()
        
        for user in org.getRelevantUsers() {
            if room.getAttending().contains(user){
                continue
            } else if users.contains(user) {
                continue
            } else {
                users.append(user)
            }
        }

        
        let v = InviteController()
        v.view.frame = UIScreen.main.bounds
        v.config(with: users, for: self.club, title: "Ping Members")
        AuthDelegate.shared.home?.navigationController?.pushViewController(v, animated: true)
    }
    
    
    // join group, send out push notification
    func handleJoinClub(){
        guard let club = club else { return }
        club.join(with: .levelB){ return }
        ToastSuccess(title: "You have tagged this channel", body: "")
        for user in club.getMembers() {
            if club.isAdmin(user) {
                setAlert(for: user.uuid, kind: .joinGroup)
            }
            if club.isCreator(user){
                UserAuthed.shared.follow(user)
            }
        }
        stack?.removeTagBtn()
    }
    
    // toggle lock
    func didTapRecord(){
        return
    }
    
}

//MARK:- HEADER + MODAL EVENT

extension AudioRoomController: AudioRoomHeaderDelegate, PhoneNumberViewDelegate {

    func onHandleDismiss(){
        if let room = self.room {
            if room.isRoot {
                club?.removeExpiredBreakoutRooms()
            }
        }
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
    func onShareNumber(){
        return
    }

    
    @objc func onTapOnBlurViewFromPhoneNumberView(sender : UITapGestureRecognizer){
        onDismissPhoneNumberView()
    }
    
    func onDismissPhoneNumberView() {
        let f = view.frame
        func fn(){
            self.phoneNumberView?.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.phoneNumberView?.removeFromSuperview()
            self.phoneNumberView = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
    }

    func onHandleSetting(){
    
        guard let club = self.club else { return }
        
        var bod = ""
        var str = ""
        
        switch club.type {
        case .home:
            bod = "This is the home room, you can hold bigger events here"
            str = "Ok"
        case .ephemeral:
            bod = "This is an one-time room, once the creator of the channel leaves, the space will shut down."
            str = "Ok"
        case .cohort:
            bod = "This is a pinned room, it will be on the home page even after everyone leaves. If you want to delete this room or change its name, tap the horizontal bar at the top of this page."
            str = "Ok"
            /*bod = club.locked
                ? "This channel is hidden, only channel members may enter this space."
                : "This channel is open, anyone can enter this space and chat with you."
            str = club.locked ? "Unlock" : "Lock"*/
        }
        
        let optionMenu = UIAlertController(title: "Room Settings", message: bod, preferredStyle: .actionSheet)
        let a1 = UIAlertAction(title: str, style: .default) //, handler: {a in
            /*if club.iamAdmin() && club.type == .cohort {
                club.toggleLock()
                ToastSuccess(title: "Give it 2 seconds", body: "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                    SwiftEntryKit.dismiss()
                    self?.grid?.header?.refresh()
                }
            }*/
        //let a2 = UIAlertAction(title: "Dismiss", style: .cancel )
        optionMenu.addAction(a1)
        //optionMenu.addAction(a2)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
}



