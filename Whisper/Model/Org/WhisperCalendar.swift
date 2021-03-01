//
//  WhisperCalendar.swift
//  byte
//
//  Created by Xiao Ling on 2/12/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//


import Foundation
import Firebase
import FirebaseAuth
import Combine
import UIKit

//MARK:- event

struct WhisperEvent {
    var ID      : String
    var name    : String
    var notes   : String
    var userID  : String
    var orgID   : String
    var clubID  : String
    var user    : User
    var start   : Int
    var end     : Int
    var timezone: String
    var timeStamp: Int
}

extension WhisperEvent : Equatable {
    static func == (lhs: WhisperEvent, rhs: WhisperEvent) -> Bool {
        return lhs.ID == rhs.ID
    }
}


/*
     Wednesday, Sep 12, 2018           --> EEEE, MMM d, yyyy
     09/12/2018                        --> MM/dd/yyyy
     09-12-2018 14:11                  --> MM-dd-yyyy HH:mm
     Sep 12, 2:11 PM                   --> MMM d, h:mm a
     September 2018                    --> MMMM yyyy
     Sep 12, 2018                      --> MMM d, yyyy
     Wed, 12 Sep 2018 14:11:54 +0000   --> E, d MMM yyyy HH:mm:ss Z
     2018-09-12T14:11:54+0000          --> yyyy-MM-dd'T'HH:mm:ssZ
     12.09.18                          --> dd.MM.yy
     10:41:02.112                      --> HH:mm:ss.SSS
 
    https://stackoverflow.com/questions/32046550/nsdate-set-timezone-in-swift
 */
func eventStartTime( for event: WhisperEvent? ) -> String {
    guard let event = event else { return "Ended" }
    let date = Date(milliseconds: event.start)
    let dateFormatterPrint = DateFormatter()
    dateFormatterPrint.timeZone = .current // TimeZone(abbreviation: "PST")
    dateFormatterPrint.dateFormat = "MMM d, h:mm a"
    let str = dateFormatterPrint.string(from: date)
    return str
}



//MARK:- calendar

class WhisperCalendar: Sink {

    /// @use: global contact list declaration and setup
    static let shared = WhisperCalendar()
    
    // @Use: store all my friends
    var cached: [String:WhisperEvent] = [:]
    var cachedAttendee:[String:[User]] = [:]
    private var listener: ListenerRegistration?

    init(){}

    /*
     @Use: when a new contact is created, pull user from
           db and cache
     */
    func await(){

        let orgs = Array(ClubList.shared.schools.keys)
        if orgs.count == 0 { return }
        
        self.listener?.remove()

        let listener = AppDelegate.shared
            .fireRef?
            .collection("calendar")
            .whereField("end", isGreaterThan: now() )
            .whereField("orgID", in: orgs)
            .addSnapshotListener { querySnapshot, error in
                
                guard let docs = querySnapshot?.documents else { return }
                
                for doc in docs {

                    guard let data  = doc.data() as? FirestoreData else { continue }
                    guard let id    = data["ID"] as? String else { continue }
                    guard let orgid = data["orgID"] as? String else { continue }
                    guard let uid   = data["userID"] as? String else { continue }
                    let deleted     = unsafeCastBool(data["deleted"])
                    if deleted { continue }
                    
                    UserList.shared.pull(for: uid){(_,_,user) in
                        guard let user = user else { return }
                        let evt = WhisperEvent(
                            ID       : id,
                            name     : unsafeCastString(data["name"]),
                            notes    : unsafeCastString(data["notes"]),
                            userID   : uid,
                            orgID    : orgid,
                            clubID   : unsafeCastString(data["clubID"]),
                            user     : user,
                            start    : unsafeCastInt(data["start"]),
                            end      : unsafeCastInt(data["end"]),
                            timezone : unsafeCastString(data["timezone"]),
                            timeStamp: unsafeCastInt(data["timeStamp"])
                        )
                        self.cached[id] = evt
                    }
                }
            }
        
        self.listener = listener
    }
    
    func getEvents( for org: OrgModel? ) -> [WhisperEvent] {
        guard let org = org else { return [] }
        let res = Array(cached.values).filter{ $0.orgID == org.uuid }
        let sorted_res = res.sorted{ $0.start < $1.start }
        return sorted_res
    }
    
    func getAttendee(for evt: WhisperEvent?, _ then: @escaping([User]) -> Void ) {

        guard let evt = evt else {
            return then([])
        }

        if let users = self.cachedAttendee[evt.ID] {

            then(users)

        } else {

            WhisperCalendar.attendeeCol(for: evt.ID)?
                .getDocuments() { (querySnapshot, err) in

                    guard let docs = querySnapshot?.documents else {
                        return then([evt.user])
                    }

                    var ids : [UserID] = []
                    
                    // get all uids
                    for doc in docs {
                        guard let data = doc.data() as? FirestoreData else { continue }
                        guard let uid = data["userID"] as? String else { continue }
                        ids.append(uid)
                    }
                    
                    // get all users
                    UserList.shared.batchWith(these: ids){ users in
                        var res = [evt.user]
                        for user in users {
                            if res.contains(user) == false {
                                res.append(user)
                            }
                        }
                        self.cachedAttendee[evt.ID] = res
                        then(res)
                    }
                }
        }
    }
    
    func get_H1(for event: WhisperEvent? ) -> String {
        guard let event = event else { return "" }
        let stem = event.notes
        guard let users = self.cachedAttendee[event.ID] else {
            return stem
        }

        let names = Array(users.prefix(5)).map{$0.get_H1()}

        var root = ""
        for name in names {
            if root == "" {
                root = "With \(name)"
            } else {
                root = "\(root), \(name)"
            }
        }
        if users.count > 6 {
            root = "\(root) and \(users.count - 5) others.\n"
        } else {
            root = "\(root).\n"
        }
        return "\(root)\(stem)"
    }
    
}

//MARK:- calendar write

extension WhisperCalendar {
    
    func rsvp(to event: WhisperEvent? ){
        guard let event = event else { return }
        let id = UserAuthed.shared.uuid
        WhisperCalendar.attendeeCol(for: event.ID)?
            .document(id)
            .setData(["userID":id,"timeStamp":now()])
    }
    
    func remove( this event: WhisperEvent? ){

        guard let event = event else { return }
        let colRef = WhisperCalendar.attendeeCol(for: event.ID)
        
        colRef?.getDocuments() { (querySnapshot, err) in
            guard let docs = querySnapshot?.documents else { return }
            for doc in docs {
                guard let data = doc.data() as? FirestoreData else { continue }
                guard let uid = data["userID"] as? String else { continue }
                colRef?.document(uid).delete()
            }
        }
        WhisperCalendar.rootRef(for: event.ID)?.delete()
        self.cached[event.ID] = nil
    }
    
    // @Use: did start the event
    func didStartEvent(at event: WhisperEvent?, in cid: String? ){
        guard let event = event else { return }
        guard let cid = cid else { return }
        WhisperCalendar.rootRef(for: event.ID)?.updateData(["clubID":cid]){e in return }
    }
    
    func didEndEvent( at room: Room? ){
        guard let room = room else { return }
        guard let club = room.club else { return }
        for (_,event) in self.cached {
            if event.clubID == club.uuid {
                WhisperCalendar.rootRef(for: event.ID)?.updateData(["clubID":""]){e in return }
            }
        }
    }
}


//MARK:- static

extension WhisperCalendar {
    
    static func create(
        name    : String,
        notes   : String,
        start   : Int,
        end     : Int,
        timezone: String,
        orgID   : String,
        _ then: @escaping(String) -> Void
    ){
        
        // get club id
        let uuid = UUID().uuidString
        
        let blob : FirestoreData = [
            "ID"      : uuid,
            "name"    : name,
            "notes"   : notes,
            "userID"  : UserAuthed.shared.uuid,
            "orgID"   : orgID,
            "start"   : start,
            "end"     : end,
            "timezone": timezone,
            "timeStamp": now(),
            "deleted"  : false,
            "clubID"   : "",
        ]
        
        WhisperCalendar.rootRef(for: uuid)?.setData(blob){ e in
            return then(uuid)
        }
    }
    
    static func rootRef( for id : String? ) -> DocumentReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let id = id else { return nil }
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("calendar").document( id )
    }
    
    static func attendeeCol( for id : String? ) -> CollectionReference? {
        return WhisperCalendar.rootRef(for: id)?.collection("users")
    }
    
}
