//
//  Club+Social.swift
//  byte
//
//  Created by Xiao Ling on 12/26/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine
import UIKit


//MARK:- room logic

extension Club {
    
    // on join audio session, increment
    func didJoinAudioSession(){
        Club.rootRef(for: self.uuid)?.updateData(["timeStampLatest":now()]){e in return }
    }
    
    func exitAllRooms( hard: Bool ){

        self.pauseCurrentPod()
        
        for (_,room) in self.rooms {
            room.leave()
            if hard {
                room.delegate = nil
            }
        }
        if hard {
            self.delegate = nil
        }
    }
    
    func createBreakoutRoom( _ then: @escaping(String) -> Void ){
        Room.create(by: UserAuthed.shared.uuid, for: self.uuid, isRoot: false ){ str in
            then(str)
        }
    }
    
    // remove all expired breakout rooms
    func removeExpiredBreakoutRooms(){
        for (id,room) in self.rooms {
            if room.getAttendingMembers().count == 0 && room.isRoot == false {
                Room.remove(this: room)
                self.rooms[id] = nil
            }
        }
    }
    
    func getRootRoom() -> Room? {
        let roots = Array(self.rooms.values)
            .filter{ $0.isRoot }
            .sorted{ $0.timeStamp < $1.timeStamp }
        return roots.count > 0 ? roots[0] : nil
    }
    
    func getBreakoutRooms() -> [Room] {
        let rooms = Array(self.rooms.values)
            .filter{ $0.isRoot == false }
            .sorted{ $0.timeStamp < $1.timeStamp }
        return rooms
    }
    
    func isLiveHere( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        let rooms = Array(self.rooms.values).filter{ $0.getAttending().contains(user) }
        return rooms.count > 0
    }
    
    
    func iamLiveHere() -> Bool {
        return isLiveHere(UserList.shared.yieldMyself())
    }
    
    func iamLive(in room:Room?) -> Bool {
        guard let room = room else { return false }
        if let me = UserList.shared.yieldMyself() {
            return room.getAttending().contains(me)
        } else {
            return false
        }
    }
    
    func someoneIsLiveHere() -> Bool {
        let rooms = Array(self.rooms.values).filter{ $0.getAttending().count > 0 }
        return rooms.count > 0
    }
    
    func getAllLivesHere() -> [User] {
        var res: [User] = []
        for (_,room) in self.rooms {
            for mem in room.getAttending() {
                if res.contains(mem) == false {
                    res.append(mem)
                }
            }
        }
        return res
    }
    
    func isVisibleToMe() -> Bool {
        return !self.locked || iCanSpeakInRooms()
    }
    
}



//MARK:- render read/write

extension Club {
    
    func changeName( to str: String? ){
        guard let str = str else { return }
        guard let ref = Club.viewRef(for: self.uuid) else { return }
        ref.updateData( ["name":str] ){ e in return }
    }
   
    // change club image
    func changeClubImage( to image : UIImage?, _ then: @escaping (Bool) -> Void ){
        
        guard let img = image else { return }
        guard AppDelegate.shared.canStore() else { return }

        let small = img.jpegData(compressionQuality: 0.10)
        let path  = "\(self.uuid)/clubImageSmall.jpg"
        UserAuthed.uploadImage( to: path, with: small ){ (succ, url) in
            guard let ref = Club.viewRef(for: self.uuid) else { return }
            ref.updateData( ["thumbURL":url, "storageURL": path] ){ e in return }
        }
    }
    
}

extension Club : Renderable {

    func get_H1() -> String {
        return self.name
    }
    
    func get_H2() -> String {
        return self.bio
    }
    
    func fetchThumbURL() -> URL? {
        if let url = self.thumbURL {
            return url
        } else {
            return nil
        }
    }
    
    func match(query: String?) -> Bool {
        return false
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    
    func getNumAttendingInAllRooms() -> Int {
        var n : Int = 0
        for (_,room) in self.rooms {
            n += room.getAttending().count
        }
        return n
    }
    
    func getAttendingInRooms() -> [User] {
        
        var head : [User] = []
        var prefix: [User] = []
        var tail : [User]  = []
        
        for (_,room) in self.rooms {
            for p in room.getAttending() {
                if p.isMe() {
                    head.append(p)
                } else if UserAuthed.shared.iAmFollowing(at: p.uuid) {
                    prefix.append(p)
                } else {
                    tail.append(p)
                }
            }
        }

        var res : [User] = []        
        for u in head {
            if res.contains(u) == false { res.append(u)}
        }
        for u in prefix {
            if res.contains(u) == false { res.append(u)}
        }
        for u in tail {
            if res.contains(u) == false { res.append(u)}
        }
        return res
    }

    func pp_attendingInRooms() -> String {
        let users = getAttendingInRooms()
        switch users.count {
        case 0 :
            return ""
        case 1:
            return "w/ \(users[0].get_H1())"
        case 2:
            return "w/ \(users[0].get_H1()) and \(users[1].get_H1())"
        case 3:
            return "w/ \(users[0].get_H1()), \(users[1].get_H1()), and \(users[2].get_H1())"
        default:
            let n = users.count - 2
            return "w/ \(users[0].get_H1()), \(users[1].get_H1()) and \(n) others"
        }
    }
    
}


//MARK:- club level social: read

extension Club {
    
    func getOrg() -> OrgModel? {
        return ClubList.shared.orgs[self.orgID]
    }
    
    // anyone who is not blocked is follower
    func getFollowers() -> [User] {
        return Array( self.members.values )
            .filter{ $0.permission != .blocked }
            .map{ $0.user }
    }

    // club members have perm level A (admin) or B (maybe speaker)
    func getMembers() -> [User] {
        return Array( self.members.values ).filter{
            $0.permission == .levelA || $0.permission == .levelB
        }.map{ $0.user }
    }
    
    func getHost( _ then: @escaping(User?) -> Void){
        UserList.shared.pull(for: creatorID){(_,_,u) in then(u) }
    }
        
    // I am admin or I am speaker
    func isAdminOrSpeaker( _ user: User? )  -> Bool {
        guard let user = user else { return false }
        if user.uuid == creatorID {
            return true
        } else {
            let res = Array(members.values)
                .filter{ $0.user.uuid == user.uuid }
                .filter{ $0.permission == .levelA || $0.permission == .levelB }
            return res.count > 0
        }
    }
    
    // Is admin if joined as levelA or is creator
    func isAdmin( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        if user.uuid == creatorID {
            return true
        } else {
            let res = Array(members.values)
                .filter{ $0.user.uuid == user.uuid
                    && $0.permission == .levelA
                }
            return res.count > 0
        }
    }
    
    func isCreator( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        return user.uuid == self.creatorID
    }
    
    func iJustJoined() -> Bool {
        let res = Array(self.members.values).filter{ $0.user.isMe() } // && $0.isFollowingMe }
        if res.count == 0 {
            return false
        } else {
            return now() - res[0].timeStamp < 3*60
        }
    }
    
    func iJustCreated() -> Bool {
        return self.creatorID == UserAuthed.shared.uuid && now() - self.timeStamp < 3*60
    }
    
    func iamAdmin() -> Bool {
        return isAdmin(UserList.shared.yieldMyself())
    }
    
    func iCanSpeakInRooms() -> Bool {
        let id = UserAuthed.shared.uuid
        if let me = members[id] {
            if me.permission == .levelA || me.permission == .levelB {
                return true
            } else {
                return !self.locked
            }
        } else {
            return !self.locked
        }
    }
    
    // @Use: criteria to sort club
    func isGreaterThan( _ club: Club? ) -> Bool {

        guard let club = club else { return true }
        if iJustJoined() && !club.iJustJoined() {
            return true
        } else if iamAdmin() && !club.iamAdmin() {
            return true
        } else if iCanSpeakInRooms() && !club.iCanSpeakInRooms() {
            return true
        } else {
            let n = self.getNumAttendingInAllRooms()
            let m = club.getNumAttendingInAllRooms()
            return n > m
        }
    }
}


//MARK:-  club logic: write

extension Club {
    
    func toggleLock(){
        if iamOwner == false { return }
        Club.rootRef(for: self.uuid)?.updateData(["locked":!self.locked]){e in return }
    }
       
    // @use: request to join club
    func requestToJoin( from uid: UserID? ){
        
    }
    
    /*
     @use: join the club
     */
    func join( _HARD_UID: String? = nil, with perm: ClubPermission, force: Bool = false, _ then : @escaping() -> Void){
        
        // do not join if club is locked
        if self.locked && !force {
            return then()
        }
        
        var myid = UserAuthed.shared.uuid
        
        if let _id = _HARD_UID {
            myid = _id
        }

        guard let ref = Club.followerRef(for: self.uuid, at: myid) else { return then() }
        let perms = fromClubPermission(perm)
        
        if let _ = members[myid] {
            let st : FirestoreData = ["permission": perms, "latest": now()]
            ref.updateData(st){ e in return then() }
        } else {
            var res = makeMemberStub(myid)
            res["permission"] = perms
            ref.setData(res){ e in return then() }
        }
        
        // join home room if this is not home room
        if self.type != .home {
            for club in ClubList.shared.fetchClubsFor(school: getOrg()) {
                if club.type == .home {
                    club.join(with: .levelB){ return }
                }
            }            
        }

        // follow everyone in this group when I choose to join this group
        if myid == UserAuthed.shared.uuid {
            UserAuthed.shared.follow(self.creator)
            for mem in getMembers() {
                UserAuthed.shared.follow(mem)
            }
        }
    }
    
    
    // Unfollow club
    func leave( _ then: @escaping() -> Void){
        let myid = UserAuthed.shared.uuid
        guard let ref = Club.followerRef(for: self.uuid, at: myid) else { return then() }
        if let _ = members[myid] {
            ref.delete()
        } else {
            return then()
        }
    }
    
    // @use: set as admin
    func setAsAdmin( at user: User?, admin: Bool ){
        guard let user = user else { return }
        join(_HARD_UID: user.uuid, with: admin ? .levelA : .levelB, force: true){ return }
    }
    
    // remove user
    func remove( _ user: User? ){
        guard let user = user else { return }
        Club.followerRef(for: self.uuid, at: user.uuid)?.delete()
        self.members[user.uuid] = nil
    }
    
    //@Use: delete this club
    func deleteClub(){
        UserAuthed.deleteMedia(at: self.storageURL)
        WhisperAnalytics.shared.didDeleteClub(at:self)
        for (id,_) in self.members {
            Club.followerRef(for: self.uuid, at: id)?.delete()
        }
        Club.rootRef(for: self.uuid)?.updateData(["deleted":true]){ e in return }
        for (_,room) in self.rooms {
            Room.remove(this: room, hard:false)
        }
        self.leave(){ return }
        ClubList.shared.didDeleteClub(at:self)
    }
    
    
    
}

