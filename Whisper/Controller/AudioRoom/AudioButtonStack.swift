//
//  AudioButtonStack.swift
//  byte
//
//  Created by Xiao Ling on 12/5/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import PopBounceButton
import UIKit


protocol AudioButtonStackDelegate: AnyObject {
    func didTapLive() -> Void
    func didTapMute() -> Void
    func didTapInvite() -> Void
    func didTapRecord()  -> Void
    func didTapShare() -> Void
    func handleJoinClub() -> Void
}

class AudioButtonStack: UIView {

    var delegate: AudioButtonStackDelegate?
    
    var showRecordingBtn: Bool = false
    var club : Club?
    var room : Room?
    
    // views
    let R : CGFloat = 45.0
    var muteBtn  : TinderButton?
    var inviteBtn: TinderButton?
    var timerBtn : TinderButton?
    var sendBtn  : TinderButton?
    
    var leaveBtn: TinderButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK:- API
    
    func config( with club: Club?, room: Room?, isOn: Bool, muted: Bool, showRecordingBtn: Bool ){
        self.showRecordingBtn = showRecordingBtn
        self.club = club
        self.room = room
        self.backgroundColor = Color.primary
    }
    
    func goLive(){

        self.setHangUpBtn()
        self.layoutMuteBtn(true)
        guard let room = room else { return }
        guard let club = room.club else { return }
        
        if club.type == .ephemeral {
            layoutInvite()
        } else if room.isRoot {
            setSendBtn()
            layoutInvite()
        }
    }
    
    func exitLive(){
        let f = self.frame
        func show(){
            self.leaveBtn?.alpha = 0.0
            self.inviteBtn?.frame  = CGRect(x:f.width, y:(f.height-R)/2,width:3*R,height:R)
            self.muteBtn?.center.x = f.width * 2
            self.timerBtn?.center.x = f.width * 2
            self.sendBtn?.center.x = f.width * 2
        }
        runAnimation( with: show, for: 0.25 ){
            self.muteBtn?.removeFromSuperview()
            self.inviteBtn?.removeFromSuperview()
            self.timerBtn?.removeFromSuperview()
            self.sendBtn?.removeFromSuperview()
            self.sendBtn  = nil
            self.timerBtn = nil
            self.muteBtn  = nil
        }
    }
    
    func setMute( muted : Bool ){
        guard let mute = muteBtn else { return }
        if muted {
            mute.changeImage(to: "mic-off", scale: 1/2, color: Color.primary)
        } else {
            mute.changeImage(to: "mic-on", scale: 0.45, color: Color.primary)
        }
        mute.backgroundColor = muted ? Color.redDark : Color.greenDark
    }
    
    func setStop( _ st : Bool ){
        guard let mute = muteBtn else { return }
        if st {
            mute.changeImage(to: "stop", scale: 1/2, color: Color.primary)
            mute.backgroundColor = Color.redDark
        } else {
            setMute(muted:true)
        }
    }
    
    func setHandRaise() {
        muteBtn?.changeImage(to: "mic-ask", scale: 1/2, color: Color.greenDark)
        muteBtn?.backgroundColor = Color.grayTertiary
    }
        
    func setLock( locked: Bool ){
        timerBtn?.changeImage(to: locked ? "locked" : "unlock", color: Color.greenDark)
        timerBtn?.backgroundColor = locked ? Color.redLite : Color.grayTertiary
    }
    
    func setRecording( _ yes : Bool ){
        guard let mute = timerBtn else { return }
        if yes {
            mute.changeImage(to: "tape", alpha: 1.0, scale: 1/2, color: Color.redDark)
            mute.backgroundColor = Color.redLite
        } else {
            mute.changeImage(to: "record", alpha: 1.0, scale: 1/2, color: Color.greenDark)
            mute.backgroundColor = Color.grayTertiary
        }
    }
    
    func removeTagBtn(){
        func fn(){ self.sendBtn?.alpha = 0.0 }
        runAnimation( with: fn, for: 0.25 ){
            self.sendBtn?.removeFromSuperview()
        }
    }
    
    //MARK:- gesture
    
    @objc func handleTapJoin(_ button: TinderButton ){
        delegate?.didTapLive()
    }
    
    @objc func handleTapLeave( _ button: TinderButton ){
        delegate?.didTapLive()
    }

    @objc func handleTapMute(_ button: TinderButton ){
        delegate?.didTapMute()
    }
    
    @objc func handleTapInvite(_ button: TinderButton ){
        delegate?.didTapInvite()
    }
    
    @objc func handleTapTimer(_ button: TinderButton ){
        delegate?.didTapRecord()
    }
    
    @objc func handleTapSend(_ button: TinderButton ){
        delegate?.didTapShare()
    }
    
    @objc func handleJoinClub(_ button: TinderButton ){
        delegate?.handleJoinClub()
    }
    
    private func layoutInvite(){
        inviteBtn?.removeFromSuperview()
        inviteBtn = nil
        let f = frame
        let btn = TinderButton()
        btn.frame = CGRect(x:f.width-2*R-24-10, y:(f.height-R)/2,width:R,height:R)
        btn.changeImage( to: "send", color:Color.greenDark )
        btn.backgroundColor = Color.grayTertiary
        btn.alpha = 0.0
        btn.addTarget(self, action: #selector(handleTapInvite), for: .touchUpInside)
        addSubview(btn)
        self.inviteBtn = btn
        
        func show() { self.inviteBtn?.alpha = 1.0 }
        runAnimation( with: show, for: 0.25 ){ return }
    }
    
    private func layoutMuteBtn( _ muted: Bool ){

        muteBtn?.removeFromSuperview()
        muteBtn = nil
        let f = frame
        let mute = TinderButton()
        mute.frame = CGRect(x:f.width-R-24, y:(f.height-R)/2,width:R,height:R)
        if muted {
            mute.changeImage(to: "mic-off", scale: 1/2, color: Color.primary)
        } else {
            mute.changeImage(to: "mic-on", scale: 0.45, color: Color.primary)
        }
        mute.backgroundColor = muted ? Color.redDark : Color.greenDark
        mute.addTarget(self, action: #selector(handleTapMute), for: .touchUpInside)
        
        mute.alpha = 0.0
        addSubview(mute)
        self.muteBtn = mute
        
        func show() { self.muteBtn?.alpha = 1.0 }
        runAnimation( with: show, for: 0.25 ){ return }
    }
    
    private func layoutTimerBtn(){

        timerBtn?.removeFromSuperview()
        timerBtn = nil

        let f = frame
        let mute = TinderButton()
        mute.frame = CGRect(x:f.width-3*R-2*24, y:(f.height-R)/2,width:R,height:R)
        mute.changeImage(to: "record", alpha: 1.0, scale: 1/2, color: Color.greenDark)
        mute.backgroundColor = Color.grayTertiary
        mute.addTarget(self, action: #selector(handleTapTimer), for: .touchUpInside)
        
        if self.showRecordingBtn {
            addSubview(mute)
            self.timerBtn = mute
        }
    }
    
    private func setSendBtn(){
        /*guard let club = club else { return }
        sendBtn?.removeFromSuperview()
        self.sendBtn = nil
        
        if club.iamAdmin() == false && club.isInClub(UserList.shared.yieldMyself()){
            return
        }

        let f = frame
        let btn = TinderButton()
        btn.frame = CGRect(x:f.width-3*R-24-20, y:(f.height-R)/2,width:R,height:R)
        btn.changeImage(to: club.iamAdmin() ? "send" : "bookmark-on", scale: 0.40, color: Color.greenDark)
        btn.alpha = 0.0
        btn.backgroundColor = Color.grayTertiary
        addSubview(btn)
        self.sendBtn = btn
            
        if club.iamAdmin() {
            btn.addTarget(self, action: #selector(handleTapSend), for: .touchUpInside)
        } else {
            btn.addTarget(self, action: #selector(handleJoinClub), for: .touchUpInside)
        }
        func show() { self.sendBtn?.alpha = 1.0 }
        runAnimation( with: show, for: 0.25 ){ return }*/
    }
    
    private func setHangUpBtn(){
        
        let f = frame

        leaveBtn?.removeFromSuperview()
        self.leaveBtn = nil
            

        let btn = TinderButton()
        btn.frame = CGRect(x: 24, y:(f.height-R)/2, width: R, height: R)
        btn.changeImage(to: "exit", scale: 0.40, color: Color.primary)
        btn.alpha = 0.0
        btn.backgroundColor = Color.primary_dark
        btn.addTarget(self, action: #selector(handleTapLeave), for: .touchUpInside)
        addSubview(btn)
        self.leaveBtn = btn
        
        func show() { self.leaveBtn?.alpha = 1.0 }
        runAnimation( with: show, for: 0.25 ){ return }
    }

}



private class ButtonContainer: UIView {
    override func draw(_ rect: CGRect) {
        applyShadow(radius: 0.2*bounds.width, opacity: 0.05, offset: CGSize(width: 0, height: 0.15 * bounds.width), color: Color.redDark)
    }
}
