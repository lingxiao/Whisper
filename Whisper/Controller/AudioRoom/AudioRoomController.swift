//
//  AudioRoomController.swift
//  byte
//
//  Created by Xiao Ling on 12/5/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import AVFoundation
import NVActivityIndicatorView



//MARK:- class

class AudioRoomController : UIViewController {
    
    // style
    var pad_top: CGFloat = 20
    var headerHeight: CGFloat = 70
    
    // data + delegate
    var club: Club?
    var room: Room?
    var recordingPath: String = ""    
    
    // style
    let stackHt: CGFloat = 50.0
    var statusHeight : CGFloat = 10.0 

    // view
    var grid   : RoomGridController?
    var stack  : AudioButtonStack?
    var analyBtn: TinderButton?
    var chatBtn : ChatButton?
    var resumeBtn: TinderTextButton?
    var emptyLabel: UITextView?
    var breakoutAlertView: TinderButton?
    var chatAlertView: TinderButton?
    var awaitView: AwaitWidget?
    
    var chatRoom: ChatRoom?
    var statView: AnalyticsController?
    
    // modal
    var blurView: UIView?
    var phoneNumberView: PhoneNumberView?

    // states
    var avPlayerActive: Bool = false
    var isBlurred : Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }

    // when view disappear, reset room layout
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.resetRoomAndFooter()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Color.primary
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        let _ = self.tappable(with: #selector(didTapOnScreen))
    }
    
    public func config( with room: Room?, club: Club? ){
        
        // set data and load all
        self.room = room
        self.club = club
        
        // Important: reset all delegates, then set this one
        ClubList.shared.resetAllDelegates()
        club?.delegate = self
        room?.delegate = self

        // get room data + club data
        room?.awaitFull()
        club?.awaitFull()
        
        // layout view + populate
        layoutGridView()
        layoutButtons()

        // go live here
        exitPrevLiveAndGoLiveHere()
        
        // listen for event
        listenForDidBlockMe(on: self, for: #selector(someoneDidBlockMe))
        
        // listen for event
        listenRoomDidDelete(on: self, for: #selector(roomDidDelete))
        
        // reload data after it has fully fetched
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 ) { [weak self] in
            self?.grid?.refresh()
        }
    }
    
    @objc func didTapOnScreen(){
        SwiftEntryKit.dismiss()
    }
    
    @objc func roomDidDelete(_ notification: NSNotification){
        //guard let room = self.room else { return }
        //guard let id = decodePayload(notification) else { return }
    }
    
    
    @objc func handleTapResumeSession(_ button: TinderTextButton ){
        func show() {
            self.resumeBtn?.alpha = 0.0
            self.emptyLabel?.alpha = 0.0
        }
        func fn(){ self.stack?.alpha = 1.0 }
        runAnimation( with: show, for: 0.25 ){
            self.exitPrevLiveAndGoLiveHere()
            self.emptyLabel?.removeFromSuperview()
            self.resumeBtn?.removeFromSuperview()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                runAnimation( with: fn, for: 0.25 ){ return }
            }
        }
    }
    
    private func exitPrevLiveAndGoLiveHere(){
        
        guard let club = club else { return }
        
        let actives = ClubList.shared.whereAmILive()
        
        if actives.count == 0 {
            
            goLive()
            
        } else {
            
            if (actives.count == 1 && club.iamLive(in:self.room)) {
                
                setMuteBtnState()
                
            } else {

                placeIndicator()
                
                // exit agora channel, remove delegates 
                AgoraClient.shared.leaveChannel(){
                    for club in ClubList.shared.whereAmILive() {
                        club.exitAllRooms(hard:true)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 ){ [weak self] in
                        self?.goLive()
                        self?.hideIndicator()
                    }
                }
            }        
        }
    }
    
    
    func setMuteBtnState(){
        
        guard let club = club else { return }

        if club.iamLiveHere(){
            self.goSetMuteBtnState()
        }
        
        if let v = self.analyBtn {
            view.bringSubviewToFront(v)
        } else {
            maybeLayoutAnalyticsBtn()
        }
        if let w = self.chatBtn {
            view.bringSubviewToFront(w)
            w.state = .dormant
        } else {
            maybeLayoutChatBtn()
        }
    }
    
    func goSetMuteBtnState(){
        guard let room = room else { return }
        guard let mem = room.audience[UserAuthed.shared.uuid] else { return }
        guard let stack = self.stack else { return }
        stack.goLive()
        switch mem.state {
        case .moderating:
            stack.setMute(muted: mem.muted)
        case .speaking:
            stack.setMute(muted: mem.muted)
        case .listening:
            stack.setHandRaise()
        case .raisedHand:
            stack.setHandRaise()
        case .podding:
            stack.setStop(true)
        case .notHere:
            stack.setMute(muted: true)
        }
    }
    
    private func resetRoomAndFooter(){
        
        guard let room = self.room else { return }
        if room.isRoot == false { return }
        if room.iamHere() { return }
        
        // reset views
        grid?.loadHeaderOnly()
        stack?.alpha = 0.0
        analyBtn?.alpha = 0.0
        chatBtn?.alpha = 0.0
        resumeBtn?.removeFromSuperview()
        resumeBtn = nil

        let f = view.frame
        let wd = f.width/2
        let ht = AppFontSize.footerBold + 30
        let ft = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (f.width-wd)/2, y: f.height - ht - 24, width: wd, height: ht)
        btn.config(with: "Resume session", color: Color.primary, font: ft)
        btn.backgroundColor = Color.redDark
        btn.addTarget(self, action: #selector(handleTapResumeSession), for: .touchUpInside)
        view.addSubview(btn)
        self.resumeBtn = btn
        
        layoutEmpty()
    }

}



//MARK:- Audio+View

extension AudioRoomController {
    
    private func layoutEmpty(){
        self.emptyLabel?.removeFromSuperview()
        let f = view.frame
        let ht = AppFontSize.H3*2
        let h2 = UITextView(frame:CGRect(x:20,y:(f.height-ht)/2,width:f.width-40, height:ht))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.body2)
        h2.text = "Tap resume to reconnect"
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = UIColor.clear
        h2.isUserInteractionEnabled = false
        self.view.addSubview(h2)
        self.emptyLabel = h2
        self.view.bringSubviewToFront(h2)
    }
    
    private func layoutGridView(){
        
        let f = view.frame
        let ht = f.height - statusHeight - stackHt
        let grid = RoomGridController()
        grid.view.frame = CGRect(x:0,y:statusHeight,width:f.width,height:ht)
        grid.view.backgroundColor = UIColor.clear
        grid.delegate = self
        grid.parentVC = self

        // mount + config
        self.grid = grid
        view.addSubview(grid.view)
        grid.config( with: room, club: self.club )
        
    }
    
    private func layoutButtons() {
        let f = view.frame
        let dy = f.height - stackHt - 30
        let v = AudioButtonStack(frame: CGRect(x:0,y:dy,width:f.width,height:stackHt+30))
        v.config( with: club, room: self.room, isOn: false, muted: true, showRecordingBtn: false)
        let _ = v.roundCorners(corners: [.topLeft,.topRight], radius: 15)
        v.delegate = self
        view.addSubview(v)
        self.stack = v
    }
    
    
    func maybeLayoutAnalyticsBtn(){

        guard let club = club else { return }
        guard let room = room else { return }
        if club.type == .ephemeral { return }

        if club.iamAdmin() == false || UserAuthed.shared.isPrivUser == false {
            analyBtn?.removeFromSuperview()
            self.analyBtn = nil
        } else {
            if self.analyBtn != nil { return }
            let f = view.frame
            let R = CGFloat(45)
            let dy = room.isRoot ? f.height - stackHt - 20 - 2*R-15 : f.height - stackHt - 20 - R - 5
            let btn = TinderButton()
            btn.frame = CGRect(x:f.width-R-24, y:dy, width:R,height:R)
            btn.changeImage( to: "chart-2", color:Color.greenDark )
            btn.backgroundColor = Color.grayTertiary
            btn.alpha = 0.0
            view.addSubview(btn)
            view.bringSubviewToFront(btn)
            self.analyBtn = btn
            func fn(){ btn.alpha = 1.0 }
            runAnimation( with: fn, for: 0.25 ){ return }
            btn.addTarget(self, action: #selector(handleTapAnalytics), for: .touchUpInside)
        }
    }
    
    func maybeLayoutChatBtn(){
        
        guard let room = room else { return }
        guard let club = club else { return }
        if room.isRoot == false { return }
        if club.type == .ephemeral { return }

        let permissioned_users = room.getAttending().filter{ $0.isPrivUser }
        
        if permissioned_users.count == 0 {
                
            self.chatBtn?.removeFromSuperview()
            self.chatBtn = nil

        } else {

            if self.chatBtn != nil {
                self.chatBtn?.alpha = 1.0
                return
            }
            
            let f = view.frame
            let R = CGFloat(45)
            let dy = f.height - stackHt - 20 - R - 5
            let btn = ChatButton(frame: CGRect(x:f.width-R-24, y:dy, width:R,height:R))
            btn.config( with: .dormant)
            let _ = btn.roundCorners(corners: [.allCorners], radius: R/2)
            btn.alpha = 0.0
            btn.delegate = self
            view.addSubview(btn)
            view.bringSubviewToFront(btn)
            self.chatBtn = btn
            func fn(){ btn.alpha = 1.0 }
            runAnimation( with: fn, for: 0.25 ){
                if let chat = room.chatItem {
                    if chat.resolved {
                        self.chatBtn?.state = .dormant
                    } else {
                        self.chatBtn?.state = .unread
                    }
                }
            }
                
        }

    }
    
    func placeIndicator(){
        
        if self.awaitView != nil { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: "Connecting")
        view.addSubview(pv)
        self.awaitView = pv

        //max duration is six seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0 ) { [weak self] in
            self?.hideIndicator()
        }        
    }
    
    // hide indicator function
    func hideIndicator(){
        awaitView?.stop()
        func hide() { self.awaitView?.alpha = 0.0 }
        runAnimation( with: hide, for: 0.25 ){
            self.awaitView?.removeFromSuperview()
            self.awaitView = nil
        }
    }
    
    //MARK:- alert modals
    
    // when everyone is in breakout room, send signal
    func alertIfEveryoneIsInBreakoutRoom(){
        
        breakoutAlertView?.removeFromSuperview()

        guard let club = self.club else { return }
        guard let root = club.getRootRoom() else { return }

        let users = club.getAttendingInRooms()
        let notMe = users.filter{ $0.uuid != UserAuthed.shared.uuid }
        if notMe.count == 0 { return }
        if users.count == root.getAttending().count { return }
                
        let f = view.frame
        let r = CGFloat(40)
        let dy = f.height-r-computeTabBarHeight()-stackHt - 20 - 3*45 - 10
        let startf = CGRect(x: f.width, y: dy, width: r, height: r)

        let v = TinderButton()
        v.frame = startf
        v.changeImage(to: "handdrag", alpha: 1.0, scale: 2/3, color: Color.primary_dark)
        v.backgroundColor = Color.white
        view.addSubview(v)
        self.breakoutAlertView = v
        func fn(){ v.frame = CGRect(x: f.width - 20 - r, y: dy, width: r, height: r) }
        func gn(){ v.frame = startf }
        runAnimation( with: fn, for: 0.15 ){
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                runAnimation( with: gn, for: 0.25 ){
                    self?.breakoutAlertView?.removeFromSuperview()
                    self?.breakoutAlertView = nil
                }
            }
        }
    }
        
}


