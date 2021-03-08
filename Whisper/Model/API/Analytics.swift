//
//  Analytics.swift
//  byte
//
//  Created by Xiao Ling on 2/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth

//MARK:- log blob

struct SpeakerLog {
    var uuid: String
    var user: User
    var prevUser: [User]
    var start: Int
    var end: Int
    var dt : Int
    var clubID: ClubID
    var roomID: RoomID
}


//MARK:- analytics singelton

class WhisperAnalytics : Sink {
    
    static let shared = WhisperAnalytics()
    
    private var clientCache: [UserID:(Room,Int)] = [:]
    private var cached : [String:SpeakerLog] = [:]
    private var didObserveClub: [ClubID] = []
        
    init(){}

    static func col() -> CollectionReference? {
        return AppDelegate.shared.fireRef?.collection("log_analytics")
    }

    static func ref( at uid: String? ) -> DocumentReference? {
        guard let uid = uid else { return nil }
        return WhisperAnalytics.col()?.document( uid )
    }
    
    static func pp_log( for log: SpeakerLog? ) -> String {
        guard let log = log else { return "" }
        let prefix = _pp_log( log.dt )
        let suffix = _pp_log(now() - log.end)
        return "Spoke for \(prefix), \(suffix) ago"
    }
    
    //MARK: - delegate fn

    func await(){ return }
    
    // when club has been loaded, await analytics
    func didLoadClub( at club: Club? ){
        /*guard let club = club else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            self?.await(for: club)
        }*/
    }

    //MARK: - db

    // await
    private func await(for club: Club){

        guard AppDelegate.shared.onFire() else { return }
        let uid = UserAuthed.shared.uuid
        if uid == "" { return }
        let clubID = club.uuid
        if clubID == "" { return }
        if club.iamAdmin() == false { return }

        if didObserveClub.contains(clubID) { return }
        self.didObserveClub.append(clubID)
        
        WhisperAnalytics.col()?
            .whereField("clubID", isEqualTo: clubID)
            // .whereField("t0", isGreaterThan: now() - 60*60*24)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                for doc in documents {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    self.fetch(data: data)
                }
            }
    }
    
    // fetch from db
    private func fetch( data: FirestoreData? ){
        guard let data = data else { return }
        guard let id = data["ID"] as? String else { return }
        guard let uid = data["userID"] as? String else { return }
        guard let rid = data["roomID"] as? String else { return }
        guard let cid = data["clubID"] as? String else { return }
        if uid == "" || rid == "" || cid == "" { return }
        if self.cached[id] != nil { return }
        UserList.shared.pull(for: uid){(_,_,user) in
            guard let user = user else { return }
            let to = unsafeCastInt(data["t0"])
            let tf = unsafeCastInt(data["t1"])
            if to >= tf  { return }
            let dt = tf - to
            let res = SpeakerLog(uuid: id, user: user, prevUser: [], start: to, end: tf, dt: dt, clubID: cid, roomID: rid)
            self.cached[id] = res
        }
    }
    
    //MARK: - read
    
    func getLog(for club: Club?) -> [RoomID:[SpeakerLog]] {
        
        guard let club = club else { return [:] }

        let items = Array(cached.values).filter{ $0.clubID == club.uuid }
        
        var res : [RoomID:[SpeakerLog]] = [:]
        
        for item in items {

            if item.roomID == "" { continue }

            if var logs = res[item.roomID]  {
                
                let to = item.start
                let all_prevs = Array(logs.filter{ $0.end <= to }.sorted{ $0.end > $1.end }).map{ $0.user }
                let prevs : [User] = all_prevs.count > 0 ? [all_prevs[0]] : []

                let log = SpeakerLog(
                    uuid: item.uuid,
                    user: item.user,
                    prevUser: prevs,
                    start: item.start,
                    end: item.end,
                    dt : item.end - item.start,
                    clubID: item.clubID,
                    roomID: item.roomID
                )
                logs.append(log)
                res[item.roomID] = logs
                
            } else {
                
                res[item.roomID] = [item]
            }
        }
        
        return res
    }
    
    func getLog(for club: Club?, at room: Room? ) -> [SpeakerLog] {

        if let _logs = getLog(for: club)[room?.uuid ?? ""] {
            
            let logs = _logs.sorted{ $0.start < $1.end }
            var res : [SpeakerLog] = []

            for log in logs {
                if res.count == 0 {
                    res.append(log)
                } else {
                    var prev = res[res.count-1]
                    let pause = log.start - prev.end
                    if prev.user == log.user && pause < 60 {
                        let dt = (prev.end - prev.start) + (log.end - log.start)
                        prev.end = log.end
                        prev.dt = dt
                        res[res.count-1] = prev
                    } else {
                        res.append(log)
                    }
                }
            }
            
            return res
            
        } else {
            return []
        }
    }

    //MARK: - write
    
    // @use: if i am speaker and i start spreaking, cache the res
    func logSpeakerStart( at room: Room?, from speaker: User? ){
        
        guard let room = room else { return }
        guard let user = speaker else { return }
        let attending = room.getAttending()
        
        // only log if I am speaking and someone else is here
        if user.isMe() == false { return }
        if attending.count == 0 { return }
        if attending.count == 1 && attending[0].uuid == UserAuthed.shared.uuid { return }
        
        if let (proom,_) = self.clientCache[user.uuid]{
            if proom.uuid != room.uuid {
                self.clientCache[user.uuid] = (room,now())
            }
        } else {
            self.clientCache[user.uuid] = (room,now())
        }
    }

    // @use: when the speaker is done speaking, log the session
    // if an only if I am the one speaking
    func logSpeakerEnd( at room: Room?, from speaker: User? ){

        guard let room = room else { return }
        guard let speaker = speaker else { return }
        guard speaker.isMe() else { return }
        
        guard let (proom,t0) = self.clientCache[speaker.uuid] else { return }

        if room.uuid != proom.uuid {

            self.clientCache[speaker.uuid] = nil

        } else {
            
            if now() - t0 < 5 { return }
            let cid = room.clubID
            let uuid = UUID().uuidString
            let oid = room.club?.getOrg()?.uuid ?? ""
            
            let res : FirestoreData = [
                "ID"    : uuid,
                "userID": speaker.uuid,
                "t0"    : t0,
                "t1"    : now(),
                "roomID": room.uuid,
                "clubID": cid,
                "orgID" : oid
            ]
            
            // log db and clear client side cache
            WhisperAnalytics.ref(at: uuid)?.setData(res){ e in return }
            self.clientCache[speaker.uuid] = nil
        }
        
        // update edge
        WhisperGraph.shared.iSpoke(to: room.getAttending())
    }
    
    func didDeleteClub( at club: Club? ){
        guard let club = club else { return }
        for (id,log) in cached {
            if log.clubID == club.uuid {
                WhisperAnalytics.ref(at: id)?.delete()
            }
        }
    }
    
    
    func didDeleteRoom( at room: Room? ){
        /*guard let room = room else { return }
        for (id,log) in cached {
            if log.roomID == room.uuid {
                WhisperAnalytics.ref(at: id)?.delete()
            }
        }*/
    }

}


private func _pp_log( _ dt: Int) -> String {

    let (hr,mint,sec) = secondsToHoursMinutesSeconds(dt)
    var a = ""
    var b = ""
    var c = ""
    if hr > 0 {
        a = "\(hr) hr "
    }
    if mint > 0 {
        b = "\(mint) min "
    }
    if sec > 0 {
        c = "\(sec) sec"
    }
    return "\(a)\(b)\(c)"
}
