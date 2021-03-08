//  ClubList.swift
//  byte
//
//  Created by Xiao Ling on 7/17/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseMessaging



/*
 @use: fetch live events for news feed
       static functions for initiating calls
 */
class ClubList : Sink {
    
    static let shared = ClubList()
    
    // list of users whom I sent push notification to
    var pushed_notifications : [UserID] = []
    
    // clubs
    var clubs : [ClubID:Club] = [:]
    var orgs: [String:OrgModel] = [:]
    var tags: [String:TagModel] = [:]
    
    
    //MARK:- data

    /*
     @use: pull from live feed
     */
    func await(){
        guard AppDelegate.shared.onFire() else { return }
        awaitOrgs()
        //purgeOldData()
    }
    
    // await orgs i'm part of
    private func awaitOrgs(){
        UserAuthed.orgColRef(for: UserAuthed.shared.uuid)?
            .whereField("didJoin", isEqualTo: true)
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? String else { continue }
                    let deleted = unsafeCastBool(data["deleted"])
                    if (!deleted){
                        self.getSchool(at: id){ _ in return }
                    }
                }
            }
    }
    
}

//MARK:- read-


extension ClubList {
    
    /*
     @Use: fetch the top org I belong to
     */
    func fetchPriorityOrg() -> (OrgModel,[Club])? {

        let res = fetchNewsFeed(withForYou: false)
        if res.count == 0 { return nil }

        let tops = res.filter{ $0.0.uuid == UserAuthed.shared.current_org_id }
        if tops.count > 0 {
            return tops[0]
        } else {
            return res[0]
        }
    }
    
    /*
     @Use: get all newsfeed. if with forYou enabled, then
           pull all live rooms into the first page
     */
    func fetchNewsFeed( withForYou: Bool = false ) -> [(OrgModel,[Club])] {
        
        var res : [(OrgModel,[Club],Int)] = []

        for (_,org) in self.orgs {
            let clubs = fetchClubsFor(school: org)
            let rooms : [Room] = Array(clubs.map{ Array( $0.rooms.values ) }.joined())
            let n : Int = rooms.filter{ $0.iamHere() }.count > 0
                ? Int(1e7)
                : rooms.map{ $0.getAttending().count }.reduce(0, +)
            res.append( (org,clubs,n) )
        }
        
        return res.sorted{ $0.2 > $1.2 }.map{ ($0.0, $0.1)  }
    }

    
    func whereAmILive() -> [Club] {
        return Array(self.clubs.values).filter{ $0.iamLiveHere() }
    }
    
    // @use: get club, load school club belong to
    func getClub( at cid: ClubID?, _ then:@escaping(Club?) -> Void ){
        
        guard let cid = cid else { return then(nil) }
        
        if let club = self.clubs[cid] {
            then(club)
        } else {
            Club.get(at: cid){ club in
                guard let club = club else { return then(nil) }
                self.clubs[cid] = club
                then(club)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                    if club.type == .ephemeral {
                        postRefreshClubPage(at:club.uuid)
                    }
                }
            }
        } 
    }
    
    
    // get school associated with org
    func getSchool( at id: String?, _ then: @escaping(OrgModel?) -> Void ){
        
        guard let id = id else { return then(nil) }
        if id == "" { return then(nil) }

        if let org = self.orgs[id] {
            then(org)
        } else {
            let org = OrgModel(at: id)
            org.await()
            self.orgs[id] = org
            then(org)
            
            org.join()
        }
    }

    // get all the clubs for this school
    func fetchClubsFor(school: OrgModel?) -> [Club] {
        guard let org = school else { return [] }
        let res = Array(self.clubs.values)
            .filter{ $0.orgID == org.uuid }
            .filter{ $0.deleted == false }
            .filter{ $0.isVisibleToMe() }
        return res
    }
    
    func fetchOrg(for club: Club? ) -> OrgModel? {
        guard let club = club else { return nil }
        return self.orgs[club.orgID]
    }
    
    // get home club for this org
    func fetchHomeClub(for club: Club?, _ then: @escaping(Club?) -> Void ){
        guard let club = club else { return then(nil) }
        self.getSchool(at: club.orgID){ org in
            let cbs = self.fetchClubsFor(school: org).filter{ $0.type == .home }
            if cbs.count > 0 {
                then(cbs[0])
            } else {
                then(nil)
            }
        }
    }
    
    // get all relevant tags for this org
    func fetchTags(for org: OrgModel? ) -> [TagModel] {
        guard let org = org else { return [] }
        let res = Array(self.tags.values).filter{ $0.taggedThisOrg(at: org) }
        return res
    }
    
    
    //MARK:- write
    
    func resetAllDelegates() {
        for (_,club) in self.clubs {
            club.delegate = nil
            for (_,room) in club.rooms {
                room.delegate = nil
                room.videoDelegate = nil
            }
        }
    }
    
    // when a user block me, remove from all clubs where it is an admin
    func thisAdminDidBlockMe( at user: User?, from club: Club? ){
        guard let _ = user else { return }
        club?.leave(){ return }
    }
    
    // remove client side reference to deleted club
    func didDeleteClub( at club: Club? ){
        guard let club = club else { return }
        let cid = club.uuid
        self.clubs[cid] = nil
        for (_,org) in self.orgs {
            let sm = org.clubIDs.filter{ $0 != cid }
            org.clubIDs = sm
        }
    }
    
}




//MARK:- push notification-

extension ClubList {
    
    // @use: see AppDelegate.swift, when remote send push alerts
    // push remote users's uid here
    public func pushPriority( at uid: UserID? ){
        return
    }
    
    // @Use: alert followers you are live.
    public func sendPushNotification( to uids: [UserID] ){
        if UserAuthed.shared.uuid == "NRC1ZCZgPMgs5Qf5D9AUohwShbw2" {
            return print("DEBUG: DO NOT SEND NOTIFICATION")
        } else {
            ClubList.pushNotification(
                  to   : uids
                , title: "\(UserAuthed.shared.get_H1()) is live."
                , body : "Swipe to join"
                , userInfo: ["callerID": UserAuthed.shared.uuid, "action": PUSH_ACTION.invite_guest_push_wake]
            ){ (succ,msg) in  return }
        }
    }

    // @Use: alert followers you are live.
    public func sendPushNotificationToSponsor( to uids: [UserID] ){
        ClubList.pushNotification(
              to   : uids
            , title: "\(UserAuthed.shared.get_H1()) just joined \(APP_NAME)"
            , body : ""
            , userInfo: ["callerID": UserAuthed.shared.uuid, "action": PUSH_ACTION.invite_guest_push_wake]
        ){ (succ,msg) in  return }

    }


    /*
     @Use: I initiate a chat with `groupId` and some `users`
    */
    static func pushNotification(
          to uids: [UserID]
        , title: String
        , body: String
        , userInfo: [String:String]
        , _ complete: @escaping Completion
    ){
        
        var small : [UserID] = []
        
        // get users that did not block themself
        for uid in uids {
            if uid == UserAuthed.shared.uid { continue }
            if let user = UserList.shared.get(uid){
                if WhisperGraph.shared.didBlockMe(this: user) == false {
                    small.append(uid)
                }
            } else {
                small.append(uid)
            }
        }        
        
        UserList.shared.batchWith(these: small){ (users) in
            if users.count == 0 { return }
            for user in users {
                guard let tok = user.pushToken else { continue }
                PushNotificationManager.shared.sendPushNotification(
                    to: tok,
                    title: title,
                    body: body,
                    payload: userInfo
                ){ (succ,msg) in complete(succ,msg) }
            }
        }
    }
}


//MARK:- admin logic

extension ClubList {
    
    private func purgeOldData(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 ) { [weak self] in
            let myid = "OLMxaVIBfRgRhnyEz5WYJD3Hj5X2"
            if UserAuthed.shared.uuid == myid {
                self?.purgeOldMedia()
                self?.purgeRooms()
                self?.purgeOldClubs()
            }
        }
    }
    
    private func purgeOldMedia(){
        let root = AppDelegate.shared.fireRef?.collection("firebase_server_task")
        root?.getDocuments() { (querySnapshot, err) in
            guard let documents = querySnapshot?.documents else { return }
            for doc in documents {
                guard let data = doc.data() as? FirestoreData else { continue }
                guard let url = data["url"] as? String else { continue }
                UserAuthed.deleteMedia(at: url)
                guard let id = data["ID"] as? String else { continue }
                root?.document(id).delete()
            }
        }
    }
    
    private func purgeOldClubs(){
        AppDelegate.shared.fireRef?
            .collection("clubs")
            .getDocuments() { (querySnapshot, err) in
                guard let documents = querySnapshot?.documents else { return }
                var clubs : [Club] = []
                for doc in documents {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? UserID else { continue }
                    let club = Club(at: id)
                    club.await()
                    club.awaitFull()
                    clubs.append(club)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0 ) { [weak self] in
                    for club in clubs {
                        if club.orgID == "" {
                            club.deleteClub()
                        }
                    }
                }
            }
    }
    
    // remove old rooms
    private func purgeRooms(){
        AppDelegate.shared.fireRef?
            .collection("rooms")
            .whereField("deleted", isEqualTo: true)
            .getDocuments() { (querySnapshot, err) in
                guard let documents = querySnapshot?.documents else { return }
                var rooms : [Room] = []
                for doc in documents {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? String else { continue }
                    let room = Room(at:id)
                    room.await()
                    rooms.append(room)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 ) { [weak self] in
                    for room in rooms {
                        Room.remove(this: room, hard: true)
                    }
                }
            }
    }
    
}
