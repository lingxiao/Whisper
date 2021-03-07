//
//  OrgModel.swift
//  byte
//
//  Created by Xiao Ling on 1/27/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine
import UIKit



//MARK:- model

class OrgModel : Sink, Renderable {
    
    var uid: String = ""
    var name: String = ""
    var bio: String = ""
    var creatorID: String = ""
    var iamOwner: Bool = false
    var bespokeOnboard: Bool = false
    var unlocked: Bool = false
    var outvite_code: String = ""

    var fetched: Bool = false
    var clubIDs: [ClubID] = []

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
        OrgModel.rootRef(for: self.uuid)?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.name = unsafeCastString(data["name"])
            self.bio  = unsafeCastString(data["bio"])
            self.creatorID = unsafeCastString(data["creatorID"])
            self.iamOwner  = self.creatorID == UserAuthed.shared.uuid
            self.unlocked  = unsafeCastBool(data["unlocked"])
            self.bespokeOnboard = unsafeCastBool(data["bespokeOnboard"])
            self.outvite_code = unsafeCastString(data["outvite_code"])
        }
    }

    // get all open clubs
    func fetchPublicClubs(){
        if self.uuid == "" { return }
        if self.fetched { return }
        self.fetched = true
        AppDelegate.shared.fireRef?
            .collection("clubs")
            .whereField("orgID", isEqualTo: self.uuid)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                for doc in documents {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? String else { continue }
                    guard let del = data["deleted"] as? Bool else { continue }
                    guard let locked = data["locked"] as? Bool else { continue }
                    self.clubIDs.append(id)
                    self.clubIDs = Array(Set(self.clubIDs))
                    if locked == false && del == false {
                        ClubList.shared.getClub(at: id){ _ in return }
                    }
                }
            }
    }
    
    //MARK:- write
    
    // @use: join this organization
    func join(){
        let res : FirestoreData = ["didJoin": true, "timeStamp": now(), "ID": self.uuid]
        UserAuthed.orgColRef(for: UserAuthed.shared.uuid)?.document(self.uuid).setData(res){ e in return }
    }
    
    func leave(){
        UserAuthed.orgColRef(for: UserAuthed.shared.uuid)?.document(self.uuid).delete(){ e in return }
    }

    
    //MARK:- render
    
    func get_H1() -> String {
        return self.name
    }
    
    func get_H2() -> String {

        let clubs = ClubList.shared.fetchClubsFor(school: self)
        
        var users : [User] = []
        for club in clubs {
            for u in club.getFollowers() {
                if users.contains(u) == false {
                    users.append(u)
                }
            }
        }
        let num = users.count
        
        var prefix = ""
        var suffix = ""
        if clubs.count > 1 {
            prefix = "\(clubs.count) channels, "
        }
        if num > 0 {
            suffix = num > 1 ? "\(num) members" : "One member"
        }
        return "\(prefix)\(suffix)"
    }
    
    func get_H3() -> String {
        return self.bio
    }
    
    func get_numHidden() -> Int {
        //let clubs = ClubList.shared.fetchClubsFor(school: self).filter{ $0.deleted == false }
        return 0 //self.clubIDs.count - clubs.count
    }
    
    func fetchThumbURL() -> URL? {
        let clubs = ClubList.shared.fetchClubsFor(school: self)
            .filter{ $0.deleted == false }
            .filter{ $0.type == .home }
        if clubs.count == 0 { return nil }
        return clubs[0].fetchThumbURL()
    }
    
    func match(query: String?) -> Bool {
        return false
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    
    func getActiveUsers() -> [User] {
        var res: [User] = []
        for club in ClubList.shared.fetchClubsFor(school: self) {
            let us = club.getAllLivesHere()
            res.append(contentsOf:us)
        }
        return res
    }
    
    // get all users in this org
    func getRelevantUsers() -> [User] {

        var head : [User] = []
        var prefix : [User] = []
        var suffix : [User] = []
        var tail   : [User] = []
        var end    : [User] = []

        for club in ClubList.shared.fetchClubsFor(school: self) {
            for user in club.getFollowers() {
                if user.isMe() {
                    head.append(user)
                } else if club.isLiveHere(user) {
                    if UserAuthed.shared.iAmFollowing(at: user.uuid) {
                        prefix.append(user)
                    } else {
                        suffix.append(user)
                    }
                } else if UserAuthed.shared.iAmFollowing(at: user.uuid) {
                    if let _ = user.fetchThumbURL() {
                        tail.append(user)
                    } else {
                        end.append(user)
                    }
                } else {
                    end.append(user)
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
        for u in suffix {
            if res.contains(u) == false { res.append(u)}
        }
        for u in tail {
            if res.contains(u) == false { res.append(u)}
        }
        for u in end {
            if res.contains(u) == false { res.append(u)}
        }
        return res
    }

}

//MARK:- static

extension OrgModel {
            
    static func rootRef( for uid : String? ) -> DocumentReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("organizations").document( uid )
    }
    
    static func bidCol() -> CollectionReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        return AppDelegate.shared.fireRef?.collection("log_org_bids")
    }
    
    
    static func create( name: String, _ then: @escaping(String) -> Void ){
        
        // get club id
        let uuid = UUID().uuidString
        let host = UserAuthed.shared.uuid
        
        OrgModel.generateFreshCode(){ code in

            // club root data
            let blob : FirestoreData = [
                "ID"             : uuid ,
                "timeStamp"      : now(),
                "timeStampLatest": now(),
                "creatorID"      : host,
                "name"           : name,
                "bio"            : "",
                "profileImageSmall": "",
                "deleted"        : false,
                "bespokeOnboard" : false,
                "unlocked"       : false,
                "parent"         : "",
                "childs"         : [],
                "outvite_code"   : ""
            ]
            
            // create club and create the home room
            // on the client web side, when a bid has been completed,
            // create the home room where all bidders are moved into the room as .levelB members
            OrgModel.rootRef(for: uuid)?.setData(blob){ e in
                Club.create(name: "Home room", orgID: uuid, type: .home, locked: false){ _ in return }
                return then(uuid)
            }
                
        }
        
    }
    
    // @internal: create a campus and add admins to it
    static func _createAndJoinAdmins( name: String, with admins: [String] ){
        OrgModel.create(name: name){ oid in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ClubList.shared.getSchool(at: oid){ org in
                    let cbs = ClubList.shared.fetchClubsFor(school: org)
                    if cbs.count == 0 { return }
                    let hm = cbs[0]
                    hm.join(with: .levelA){ return }
                    for id in admins {
                        hm.join( _HARD_UID: id, with: .levelA, force: true){ return }
                    }
                }
            }
        }
    }
    
    // @use: get phone number
    static func generateFreshCode( _ then: @escaping(String) -> Void){

        // punt and say one of these is new random #
        let c1 = randomPhoneNumber()
        let c2 = randomPhoneNumber()
        let c3 = randomPhoneNumber()

        OrgModel.query(at: c1){ org in
            if let _ = org {
                OrgModel.query(at: c2){ org in
                    if let _ = org {
                        return then(c3)
                    } else {
                        return then(c2)
                    }
                }
            } else {
                return then(c1)
            }
        }
    }
    
    // @use: search for club at code
    static func query( at code: String?, _ then: @escaping(OrgModel?) -> Void ){
        
        guard let code = code else { return then(nil) }
        
        AppDelegate.shared.fireRef?
            .collection("organizations")
            .whereField("outvite_code", isEqualTo: code)
            .whereField("deleted", isEqualTo: false)
            .getDocuments() { (querySnapshot, err) in

                guard let docs = querySnapshot?.documents else {
                    return then(nil)
                }

                var res : [ClubID] = []

                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? String else { continue }
                    res.append(id)
                }
                
                if res.count == 0 {
                    return then(nil)
                } else {
                    ClubList.shared.getSchool(at: res[0]){ org in then(org) }
                }
            }
    }

}

