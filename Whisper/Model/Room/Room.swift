//
//  Room.swift
//  byte
//
//  Created by Xiao Ling on 12/6/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase


//MARK:- class

private let HEART_BEAT_INTERVAL = Int(45)

class Room : Sink {
        
    // data
    var uid: String = ""
    var clubID: String = ""
    var club: Club?
    var createdBy: UserID = ""
    
    var call_state: CallState = .ended
    //var room_mode : RoomPerm  = .open
    var isRoot    : Bool = true
    var timeStamp : Int = 0
    var isRecording: Bool = false
    var entryTimeStamp: Int = ThePast()
    
    // audience + media
    var audience: [UserID:RoomMember] = [:]
    var chatItem: RoomChatItem?

    // user event delegate
    var delegate: RoomDelegate?
    var chatDelegate: RoomChatDelegate?
    var videoDelegate: RoomVideoDelegate?
    
    var deleted: Bool = false
    var deleteDate: Int = 0
    
    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }
        
    init( at id: String! ){
        self.uid = id
    }

    //MARK:- data

    func await() {
        if self.uuid == "" { return }
        awaitRoot()
        awaitAudience()
    }
    
    func awaitFull(){
        awaitChat()
    }
    
    //MARK:- READ
    
    func getAttendingMembers() -> [RoomMember] {
        return Array(audience.values).filter{ $0.state != .notHere }
    }

    func getAttending() -> [User] {
        return getAttendingMembers().map{ $0.user }
    }

    func getAttendingSpeakers() -> [RoomMember] {
        return getAttendingMembers().filter{ $0.state == .speaking }
    }
    
    func pp_attending() -> String {
        
        let here = getAttending()
        
        switch here.count {
        case 0 :
            return ""
        case 1:
            return "\(here[0].get_H1()) is LIVE"
        case 2:
            return "\(here[0].get_H1()) and \(here[1].get_H1()) are chatting"
        case 3:
            return "\(here[0].get_H1()), \(here[1].get_H1()), and 1 other is chatting"
        case 4:
            return "\(here[0].get_H1()), \(here[1].get_H1()) and 2 others are chatting"
        default:
            let n = Double(here.count-2).formatPoints()
            return "\(here[0].get_H1()),  \(here[1].get_H1()) and \(n) others are chatting"
        }
    }
    
    func getMember( _ uid: UserID? ) -> RoomMember? {
        guard let id = uid else { return nil }
        return audience[id]
    }
    
    func getMyRecord() -> RoomMember? {
        return getMember(UserAuthed.shared.uuid)
    }
    
    
    func numAttending() -> Int {
        return getAttending().count
    }
    
    func iamHere() -> Bool {
        return getAttending().filter{ $0.isMe() }.count > 0
    }
    
    func isMuted( at user: User? ) -> Bool {
        guard let user = user else { return false }
        if let m = audience[user.uuid] {
            return m.muted
        } else {
            return false
        }
    }
    
    func iamMuted() -> Bool {
        return isMuted(at: UserList.shared.yieldMyself())
    }
    
    func isSpeaking( at user: User? ) -> Bool {
        guard let user = user else { return false }
        if let m = audience[user.uuid] {
            return m.state == .speaking
        } else {
            return false
        }
    }
    
    func getAgoraSpeaker( with tok: UInt ) -> RoomMember? {
        let t = "\(tok)"
        let m = Array(self.audience.values).filter{ $0.agoraTok == t }
        return m.count > 0 ? m[0] : nil
    }
    

    // get all people that's in this club but is not in this room
    func inClubButNotInRoom() -> [User] {
        var users : [User] = []
        if let club = ClubList.shared.clubs[self.clubID] {
            users = club.getFollowers()
        }
        let here = self.getAttending()
        users = users.filter{ here.contains($0) == false }
        return users
    }

    
    //MARK:- live users generated events
    
    func join( asSpeaker: Bool = false ){
        
        if iamHere() { return }

        let uid = UserAuthed.shared.uuid
        var res = makeRoomMemberStub(uid)
        
        res["beat"]  = now()
        res["muted"] = true
        res["state"] = asSpeaker
            ? fromRoomMemberState(.speaking)
            : fromRoomMemberState(.listening)
            
        Room.audienceRef(for: self.uuid, at: uid)?.setData(res){ e in return }
        
        if self.call_state == .ended {
            let st : FirestoreData = ["state":stateCall(.liveHostAudio), "timeStamp":now()]
            Room.rootRef(for: self.uuid)?.updateData(st){ e in return }
        }
        
        self.club?.didJoinAudioSession()
        
        // log entry + heartbeat
        heartBeat()
        self.entryTimeStamp = now()
    }

    func leave(){
        
        if self.iamHere() == false { return }
        
        self.club?.didJoinAudioSession()

        let uid = UserAuthed.shared.uuid

        // reset room root
        if numAttending() == 1 && iamHere() {
            let st : FirestoreData = ["state":stateCall(.ended), "timeStamp":now(), "isRecording": false]
            Room.rootRef(for: self.uuid)?.updateData(st){ e in return }
            Room.chatRef(for: self.uuid)?.delete()
        }
        
        Room.audienceRef(for: self.uuid, at: uid)?.setData( makeRoomMemberStub(uid) ){ e in return }
        
        // log duration >> this is extermely buggy
        if self.entryTimeStamp != ThePast() {
            let _id = UUID().uuidString
            let log : FirestoreData = [
                "ID"    :_id,
                "roomID":self.uuid,
                "clubID": self.clubID,
                "userID":UserAuthed.shared.uuid,
                "t0"    :self.entryTimeStamp,
                "t1"    :now()
            ]
            Room.durationRef(for: _id)?.setData(log){e in return }
            self.entryTimeStamp = ThePast()
        }
        
        // if club is emphemeral and I am
        // the owner or the only one here, then
        // remove the club
        guard let club = self.club else { return }
        
        if club.type == .ephemeral {
            if club.iamOwner {
                for mem in getAttending() {
                    if mem.isMe() { continue }
                    Room.audienceRef(for: self.uuid, at: mem.uuid)?.setData( makeRoomMemberStub(uid) ){ e in return }
                }
                club.deleteClub()
            } else {
                let here = getAttending()
                if here.count == 0 || (here.count == 1 && here[0].isMe()) {
                    club.deleteClub()
                }
            }
        }
        
        // alert calendar this event has ended
        WhisperCalendar.shared.didEndEvent(at: self)
    }
    
    // set agora token
    func setToken( to tok: UInt ){
        let myuid = UserAuthed.shared.uuid
        Room.audienceRef( for: self.uuid, at: myuid)?.updateData( ["agoraTok": "\(tok)","timeStamp": now()]){ e in return }
    }
    
    // @use: boot disconnected user, if it is not in podding state
    func logDisconnectedUser( with tok : UInt ){

        guard let club = self.club else { return }
        if !club.iamAdmin(){ return }

        for (_,mem) in self.audience {
            if mem.agoraTok == "\(tok)" && mem.state != .podding {
                expel(this: mem.user)
            }
        }
    }


    // expel user from room
    func expel( this user: User? ){
        guard let user = user else { return }
        Room.audienceRef(for: self.uuid, at: user.uuid)?.setData( makeRoomMemberStub(user.uuid) ){ e in return }
    }
    
    // @use: shut down room.
    func shutDown( _ then: @escaping() -> Void){
        
        guard let club = self.club else { return then() }
        if club.iamAdmin() == false { return then() }

        for user in getAttending() {
            Room.audienceRef(for: self.uuid, at: user.uuid)?
                .setData( makeRoomMemberStub(user.uuid) ){ e in return }
        }
        
        let st : FirestoreData = ["state":stateCall(.ended), "timeStamp":now(), "isRecording":false]
        Room.rootRef(for: self.uuid)?.updateData(st){ e in return }
        Room.chatRef(for: self.uuid)?.delete()

        then()
    }
    
    func maybeMute() {
        let myuid = UserAuthed.shared.uuid
        if let m = audience[myuid] {
            let b = m.muted ? false : true
            Room.audienceRef( for: self.uuid, at: myuid)?.updateData( ["muted": b ,"timeStamp": now()]){ e in return }
        }
    }
    
    func setSpeaking( to b: Bool ) {
        let myuid = UserAuthed.shared.uuid
        let st = fromRoomMemberState(.speaking)
        if let _ = audience[myuid] {
            Room.audienceRef( for: self.uuid, at: myuid)?.updateData( ["state": st ,"timeStamp": now()]){ e in return }
        }
    }
    
    func setPodding( to isPodding: Bool, _ then: @escaping() -> Void ){

        let myuid = UserAuthed.shared.uuid
        var altSt : RoomMemberState =  .listening

        if let club = self.club {
            if club.iamAdmin() || club.iCanSpeakInRooms() {
                altSt = .speaking
            }
        }
        
        let st = fromRoomMemberState(  isPodding ? .podding : altSt )
        let blob : FirestoreData = isPodding
            ? ["state": st,"muted":true, "timeStamp": now()]
            : ["state": st, "timeStamp": now() ]

        if let _ = audience[myuid] {
            Room.audienceRef( for: self.uuid, at: myuid)?.updateData(blob){ e in
                return then()
            }
        } else {
            return then()
        }
    }
    
    func standUp( this user: User? ){
        guard let user = user else { return }
        let st = fromRoomMemberState(.speaking)
        if let _ = audience[user.uuid] {
            Room.audienceRef( for: self.uuid, at: user.uuid)?
                .updateData(["muted":true, "state": st, "timeStamp": now()]){ e in return }
        }
    }
    
    func sitDown( this user: User? ){
        
        guard let user = user else { return }
        guard let club = club else { return }

        if user.isMe() || club.iamAdmin() {
            let st = fromRoomMemberState(.listening)
            Room.audienceRef( for: self.uuid, at: user.uuid)?
                .updateData( ["state": st, "timeStamp": now()]){ e in return }
        }
    }

    /*func makeMod( by uid: UserID?, for id : UserID? ){
        let myuid = UserAuthed.shared.uuid
        if let _ = audience[myuid] {
            Room.audienceRef( for: self.uuid, at: myuid)?
                .updateData(["isMod":true, "onStage": true, "timeStamp": now()]){ e in return }
        }
    }*/
    
    func raiseHand(){
        let id = UserAuthed.shared.uuid
        if let _ = audience[ id ] {
            let st = fromRoomMemberState(.raisedHand)
            Room.audienceRef( for: self.uuid, at: id )?
                .updateData(["state":st,"timeStamp": now()]){ e in return }
        }
    }
    
    func setIsRecording(){
        Room.rootRef(for: self.uuid)?.updateData(["isRecording":true]){ e in return }
    }
    
    func setNotRecording(){
        Room.rootRef(for: self.uuid)?.updateData(["isRecording":false]){ e in return }
    }

    
}

//MARK:- log user presene in room

extension Room {
    
    // log presence every 45 seconds
    // with some likelihood, purge dead roomates
    private func heartBeat(){
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(HEART_BEAT_INTERVAL) ) { [weak self] in
            guard let self = self else { return }
            if self.iamHere() == false { return }
            Room.audienceRef( for: self.uuid, at:UserAuthed.shared.uuid)?
                .updateData( ["beat": now()]){ e in return }
            self.purgeDeadRoomates()
            self.heartBeat()
        }
    }
    
    // If I am the latest one to join the room,
    // then it's my duty to purge roomates with no heart beat for two cycles
    private func purgeDeadRoomates(){
        let mems = getAttendingMembers().sorted{ $0.joinedTime > $1.joinedTime }
        if mems.count == 0 { return }
        if mems[0].user.isMe() == false { return }
        for aud in mems {
            let dead = aud.beat < now() - 2*HEART_BEAT_INTERVAL
            if dead && aud.user.isMe() == false {
                self.expel(this: aud.user)
            }
        }
    }
}


//MARK:- static

extension Room {
    
    static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.uuid == rhs.uuid
    }

    
    // create a new room
    static func create(
        by uid: UserID = "",
        for cid : ClubID = "",
        isRoot: Bool = false,
        _ then: @escaping(String) -> Void )
    {

        let id = UUID().uuidString

        let blob : FirestoreData = [
            "ID"        : id,
            "clubID"    : cid,
            "createdBy" : uid,
            //"permission": permRoom(perm),
            "state"     : stateCall(.ended),
            "isRoot"    : isRoot,
            "timeStamp" : now(),
            "isRecording": false,
            "deleted"    : false,
            "deleteDate" : 0
        ]
        
        Room.rootRef(for: id)?.setData(blob){ e in return then(id) }
    }
    
    static func remove( this room: Room?, hard: Bool = false ){
        
        guard let room = room else { return }
        
        WhisperAnalytics.shared.didDeleteRoom(at: room)
        Room.chatRef(for: room.uuid)?.delete()
        
        let auto = room.deleted && room.deleteDate < now() - 6*60*60
        let rmv_data = hard || auto
        
        if rmv_data {
            Room.rootRef(for: room.uuid)?.delete()
        } else {
            Room.rootRef(for: room.uuid)?.updateData(["deleted":true, "deleteDate":now()])
        }
        for (uid,_) in room.audience {
            Room.audienceRef(for: room.uuid, at: uid)?.delete()
        }
    }
    
    static func rootRef( for id : String? ) -> DocumentReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("rooms").document( id )
    }

    static func audienceCollectionRef( for id: String? ) -> CollectionReference? {
        return Room.rootRef(for: id)?.collection("users")
    }
    
    static func audienceRef( for id: String?, at uid: UserID? ) -> DocumentReference? {
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        guard let id = id else{ return nil }
        if id == "" { return nil }
        return Room.audienceCollectionRef(for: id)?.document(uid)
    }
    
    static func chatRef( for id: RoomID? ) -> DocumentReference? {
        guard let uid = id else { return nil }
        if uid == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("rooms_chat").document( uid )
    }


    static func mediaCollectionRef( for id: String? ) -> CollectionReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return Room.rootRef(for: id)?.collection("media")
    }
    
    static func mediaRef( for id: String?, at uid: String? ) -> DocumentReference? {
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        return Room.mediaCollectionRef(for: id)?.document(uid)
    }
    

    static func durationRef( for id: String? ) -> DocumentReference? {
        guard let uid = id else { return nil }
        if uid == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("log_room_duration").document( uid )
    }
    
    
}

