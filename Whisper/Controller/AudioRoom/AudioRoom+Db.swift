//
//  AudioRoom+Db.swift
//  byte
//
//  Created by Xiao Ling on 12/27/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import AVFoundation



//MARK:- GO/Exit live

extension AudioRoomController {
    
    // leave room
    public func exitLive( _ then: @escaping() -> Void){
        club?.pauseCurrentPod()
        room?.leave()
        AgoraClient.shared.leaveChannel(){ then() }
    }
    
    //@use: exit current channel, then enter this channel
    public func goLive( autoAlert: Bool = true ){
        if AgoraClient.shared.inChannel() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) { [weak self] in
                if AgoraClient.shared.inChannel() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                        self?.goExecuteLiveRoutine(autoAlert)
                    }
                } else {
                    self?.goExecuteLiveRoutine(autoAlert)
                }
            }
        } else {
            goExecuteLiveRoutine(autoAlert)
        }
    }
    
    
    // @Use:
    private func goExecuteLiveRoutine( _ autoAlert: Bool ){
        
        guard let room = room else { return }
        guard let club = self.club else { return }
        
        // set as delegate first, this is very important
        AgoraClient.shared.delegate = self
        
        // join channel
        AgoraClient.shared.joinChannel(at: room.uuid, host: false){ b in
            
            if !b { return ToastSuccess(title: "", body: "Failed to join channel") }
            
            // set delegates here
            AgoraClient.shared.delegate = self
            club.delegate = self
            room.delegate = self
            
            // mute myself, and join based on permission
            AgoraClient.shared.mute()
            room.join( asSpeaker: club.iamAdmin() ) // OR DO: club.iCanSpeakInRooms()

            // update view
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                self?.setMuteBtnState()
                self?.maybeLayoutAnalyticsBtn()
                self?.maybeLayoutChatBtn()
            }
        }

        // send push notification to people who want to receive it
        if autoAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 ) { [weak self] in
                self?.alertGroupMembers( aggressive: true )
            }
        }
        
        // show alert to user if everyone is in the breakout rooms
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            self?.alertIfEveryoneIsInBreakoutRoom()
        }
    }    
}

//MARK:- blocking event

extension AudioRoomController {
    
    @objc func someoneDidBlockMe(_ notification: NSNotification){
        
        guard let club = club else { return }
        guard let uid = decodePayloadForUserID(notification) else { return }
        
        // if I"m admin do nothing
        let me = UserList.shared.yieldMyself()
        if club.isAdmin(me) { return }

        // else remove from the room if user is admin
        UserList.shared.pull(for: uid){(_,_,user) in

            guard let user = user else { return }
            if club.isAdmin(user){
                self.didTapLive()
                ClubList.shared.thisAdminDidBlockMe(at: user, from: self.club)
            }
            
        }
    }
}


//MARK:- database event for the club I'm in

extension AudioRoomController: ClubDelegate {
    
    func didDeleteClub(at club: Club) {
        guard let _club = self.club else { return }
        if club.uuid != _club.uuid { return }
        ToastSuccess(title: "This channel has ended", body: "")
        exitLive(){ return }
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }

    func didChangeLock( to locked: Bool ){
        stack?.setLock(locked: locked)
        if locked {
            ToastSuccess(title: "Locked", body: "This call is locked until the space is open")
        } else {
            ToastSuccess(title: "Unlocked", body: "This call is now open to all members")
        }
    }
    
    
    // on new playlist added, refresh grid
    func didAddPlayList(){
        grid?.refresh()
    }
    
    
}

//MARK:- room live state delegate

extension AudioRoomController: RoomDelegate {    
    
    func didLiveHostAudio() {
        return
    }
    
    // If remote shut down room, then exit
    func didExitLive( from room: Room ) {
        exitLive(){ return }
    }
    
    // if I have been kicked out
    // exit the live automatically
    func onNewAudience(at user: RoomMember, didJoin: Bool) {
        if didJoin {
            grid?.insert(user)
        } else {
            grid?.remove(user)
            if user.user.isMe() {
                exitLive(){ return }
            }
        }
    }
    
    func onNewOnStage(at user: RoomMember, on stage: Bool) {
        guard let room = room else { return }
        grid?.refresh()
        if user.user.isMe() && room.iamHere() {
            if stage {
                stack?.setMute(muted: user.muted)
                AgoraClient.shared.setAsHost()
            } else {
                stack?.setHandRaise()
                AgoraClient.shared.setAsGuest()
            }
        }
    }
    
    func onNewModerator(at user: RoomMember, isMod: Bool) {
        return
    }
    
    func onPodding(at user: RoomMember, podding: Bool){
        grid?.refresh()
        if user.user.isMe() {
            if podding {
                self.stack?.setStop(true)
            } else {
                if let room = self.room {
                    self.stack?.setMute(muted: room.iamMuted())
                } else {
                    self.stack?.setMute(muted: true)
                }
            }
        }
    }
    
    /*
     @use: respond to mute event:
         at less than 15 speakers: mute
         else cut to guest mode for agora
    */
    func didChangeMute(at user: RoomMember, to muted: Bool) {
        
        if user.user.isMe(){

            if user.state == .podding {

                stack?.setStop(true)

            } else {

                stack?.setMute(muted: muted)

                if muted {
                    
                    if let room = self.room {
                        if room.getAttendingSpeakers().count <= 15 {
                            AgoraClient.shared.mute()
                        } else {
                            AgoraClient.shared.setAsGuest()
                        }
                    } else {
                        AgoraClient.shared.setAsGuest()
                    }

                } else {
                    if let room = self.room {
                        if room.getAttendingSpeakers().count <= 15 {
                            redudantJoinChannel(){
                                AgoraClient.shared.unMute()
                            }
                        } else {
                            redudantJoinChannel(){
                                AgoraClient.shared.setAsHost()
                            }
                        }
                    } else {
                        redudantJoinChannel(){
                            AgoraClient.shared.setAsHost()
                        }
                    }
                }
            }
        }
    }
    
    // if no in channel for some reason join now
    private func redudantJoinChannel( _ then: @escaping() -> Void ){
        if AgoraClient.shared.inChannel() { return then() }
        guard let room = room else { return then() }
        AgoraClient.shared.joinChannel(at: room.uuid, host: true ){ b in
            AgoraClient.shared.delegate = self
            then()
        }
    }
    
    func onRaiseHand( at user: RoomMember, raised: Bool ){
        grid?.refresh()
    }
    
    
    func onNewChatItem( in room: Room, with: RoomChatItem ){
        guard let _room = self.room else { return }
        if room.uuid != _room.uuid { return }
        chatBtn?.state = .unread
    }

    func onTypingNewChat( in room: Room ){
        guard let _room = self.room else { return }
        if room.uuid != _room.uuid { return }
        chatBtn?.state = .typing        
    }

    func didStartRecord(){

        guard let club = club else { return }
        ToastSuccess(title: "The conversation is now being recorded", body: "")

        if club.iamOwner {
            stack?.setRecording(true)
        }
    }


    func didEndRecord(){

        guard let club = club else { return }
        ToastSuccess(title: "The recording has stopped", body: "")

        if club.iamOwner {
            stack?.setRecording(false)
        }
    }
}

//MARK:- agora delegate

extension AudioRoomController : AgoraClientAppDelegate {

    // after joining agora event, set agora token for this session
    func didJoinLocal(with tok: UInt) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.room?.setToken(to: tok)
        }
    }
    
    func didJoinRemote(with tok: UInt) {
        //print(">> remote entered with: \(tok)")
    }
    
    // if token has exited, then log the exit event after a slight delay
    // Delay by random amt so that events do not cross
    func didLeave(with tok: UInt) {
        let dt = Double( Int.random(in: 0..<200) )/100.0
        DispatchQueue.main.asyncAfter(deadline: .now() + dt ) { [weak self] in
            self?.room?.logDisconnectedUser(with: tok)
        }
    }

    /*
     @use: given map:
        - agorakToken : Volume
        - where volume is 0 ..< 255
        - broadcast spekaer
     */
    func volumeIndicator( from speakers: [UInt:UInt] ){

        guard let room = self.room else { return }
        let mid = UserAuthed.shared.uuid

        for (tok,vol) in speakers {
            
            let mem = tok == 0
                ? room.getMember(mid)
                : room.getAgoraSpeaker(with: tok)
            
            if let mem = mem {
                if vol > 10 && mem.muted == false {
                    postDidSpeaking(userID: mem.user.uuid, roomID: room.uuid)
                    WhisperAnalytics.shared.logSpeakerStart(at: self.room, from: mem.user)
                } else {
                    postDidUnSpeaking(userID: mem.user.uuid, roomID: room.uuid)
                    WhisperAnalytics.shared.logSpeakerEnd(at: self.room, from: mem.user)
                }
            }
        }
    }

    private func alertGroupMembers( aggressive: Bool ){

        guard let room = self.room else { return }
        if !AgoraClient.shared.inChannel() { return }
        
        let full : [User] = room.inClubButNotInRoom()
        
        if aggressive {

            ClubList.shared.sendPushNotification(to: full.map{ $0.uuid })

        } else {
            
            let small : [User] = full.filter{ UserAuthed.shared.isFollowedBy(at: $0.uuid ) }
            ClubList.shared.sendPushNotification(to: small.map{ $0.uuid })

        }

    }

}

