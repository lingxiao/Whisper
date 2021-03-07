//
//  Club.swift
//  byte
//
//  Created by Xiao Ling on 11/15/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine
import UIKit


//MARK:- club

protocol ClubToClubListDelegate {
    func didSyncOrgID( from club: Club ) -> Void
}


class Club : Sink {
    
    var delegate: ClubDelegate?
    var _listDelegate: ClubToClubListDelegate?
    
    // view
    var uid      : String!
    var name     : String = ""
    var bio      : String = ""
    var thumbURL : URL?
    var numEdits : Int = 0
    var deleted  : Bool = false
    var storageURL: String = ""
    
    // ownership
    var orgID: String = ""
    var creatorID: String = ""
    var iamOwner : Bool = false
    var creator  : User?
    var outvite_code: String = ""
    var locked: Bool = false
    
    // type
    var type: ClubType = .cohort
    
    // time
    var timeStamp: Int = ThePast()
    var timeStampLatest: Int = ThePast()

    // members + rooms
    var members : [UserID:ClubMember] = [:]
    var rooms   : [RoomID:Room] = [:]
    

    // pods
    var media: [String: PodPlayList] = [:]
    var currentPlayList: PodPlayList?
    var prevPlayList: [String] = []
    
    // cards
    var deckIDs: [DeckID] = []

    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }

    init( at id: String! ){
        self.uid = id
    }
    
    @objc func roomDidDelete(_ notification: NSNotification){
        if let id = decodePayload(notification) {
            self.rooms[id] = nil
        }
    }

    func await() {
        
        // listen for event
        listenRoomDidDelete(on: self, for: #selector(roomDidDelete))

        if self.uuid == "" { return }
        
        // root
        Club.rootRef(for: self.uuid)?.addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            
            let prev_orgid = self.orgID
            
            self.type         = clubType( unsafeCastString( data["type"] ) )
            self.orgID        = unsafeCastString(data["orgID"])
            self.creatorID    = unsafeCastString(data["creatorID"])
            self.iamOwner     = self.creatorID == UserAuthed.shared.uuid
            self.locked       = unsafeCastBool(data["locked"])
            self.outvite_code = unsafeCastString(data["outvite_code"])
            self.timeStampLatest = unsafeCastInt(data["timeStampLatest"])
            self.timeStamp = unsafeCastInt(data["timeStamp"])

            self.getHost(){ user in
                self.creator = user
            }
                        
            // once org id has been synced, fetch the org 
            // this club is part of
            if prev_orgid != self.orgID {
                self._listDelegate?.didSyncOrgID(from: self)
            }
            
            
            let prev_del = self.deleted
            self.deleted = unsafeCastBool(data["deleted"])
            if prev_del != self.deleted {
                postRefreshClubPage(at:self.uuid)
                if self.deleted {
                    self.delegate?.didDeleteClub(at: self)
                }
            }

            self.storageURL = unsafeCastString(data["storageURL"])

        }
        
        // view
        Club.viewRef(for: self.uuid)?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.name = unsafeCastString(data["name"])
            self.bio  = unsafeCastString(data["bio"])
            self.numEdits = unsafeCastIntToZero(data["numEdits"])
            if let url = data["thumbURL"] as? String {
                self.thumbURL = URL(string: url)
                self.cacheImage()
            }
        }

        // await followers
        Club.followerCollectionRef( for: self.uuid )?
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    decodeClubMember(data){ mem in
                        guard let mem = mem else { return }
                        self.members[mem.uuid] = mem
                    }
                }
        }
            
        // await root room
        awaitRooms(isRoot: true)
        awaitRooms(isRoot: false)        
    }
    
    // get club analytics
    // Todo: if you decide to show analystics, then uncomment this
    public func awaitFull(){
        //WhisperAnalytics.shared.await(for:self)
    }
    
    private func awaitRooms( isRoot: Bool ){

        // await rooms
        AppDelegate.shared.fireRef?
            .collection("rooms")
            .whereField("clubID",  isEqualTo: self.uuid)
            .whereField("isRoot", isEqualTo: isRoot)
            .whereField("deleted", isEqualTo: false)
            .addSnapshotListener { querySnapshot, error in
             
                guard let documents = querySnapshot?.documents else { return }
            
                for doc in documents {
                    guard let data = doc.data() as? FirestoreData else {
                        continue
                    }
                    guard let id = data["ID"] as? UserID else { continue }
                    
                    if let _ = self.rooms[id] {
                        continue
                    } else {
                        let room = Room(at:id)
                        room.clubID = self.uuid
                        room.club = self
                        room.await()
                        self.rooms[id] = room
                        if isRoot == false {
                            postBreakoutRoomDidAdd(roomID:id)
                        }
                    }
                }
            }

    }
    
    
    private func cacheImage(){
        if let small = thumbURL {
            let source = ImageLoader.shared.loadImage(from: small )
            let _ = source.sink { _ in return }
        }
    }
}


// MARK:- static

extension Club : Equatable {
        
    static func == (lhs: Club, rhs: Club) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    /*
     @use: create new club
    */
    static func create(
        name : String,
        orgID: String = "",
        type : ClubType,
        locked: Bool,
        _ then: @escaping(ClubID?) -> Void
    ){
        
        let host = UserAuthed.shared.uuid

        // generate a fresh phone number
        Club.generateFreshPhoneNumber(){ outvite_code in
            
            // get club id
            let uuid = UUID().uuidString

            // club root data
            let blob : FirestoreData = [
                "ID"             : uuid ,
                "timeStamp"      : now(),
                "timeStampLatest": now(),
                "creatorID"      : host,
                "orgID"          : orgID,
                "outvite_code"   : outvite_code,
                "locked"         : locked,
                "deleted"        : false,
                "widgets"        : [],
                "type"           : typeClub(type)
            ]
            
            Club.rootRef(for: uuid)?.setData(blob){ e in return }
            
            // view
            let stat : FirestoreData = [
                "numFollowers"   : 1,
                "numLives"       : 0,
                "name"           : name,
                "bio"            : "",
                "thumbURL"       : "",
                "storageURL"     : "",
                "numNameEdits"   : 0,
            ]
            
            Club.viewRef(for: uuid)?.setData(stat){ e in return }
            
            // create default audio room
            Room.create(by: host, for: uuid, isRoot: true ){ _ in return }
            
            // add host
            var host_record = makeMemberStub(host)
            host_record["iamFollowing"] = true
            host_record["isFollowingMe"] = true
            Club.followerRef(for: uuid, at: host)?.setData(host_record){ e in return }
            let res : FirestoreData = [ "didJoin": true, "timeStamp": now(), "ID": uuid ]
            UserAuthed.clubRef(for: host, at: uuid)?.setData(res){ e in return }
            
            then( uuid )
        }
    }
    
    // get a club
    static func get( at id: ClubID?, _ then: @escaping(Club?) -> Void ){
        
        guard let id = id else { return then(nil) }
        if id == "" { return then(nil) }
        
        Club.rootRef(for:id)?.getDocument { documentSnapshot, error in
            
            if ( error != nil || documentSnapshot == nil){
                return then(nil)
            }
            
            guard let doc = documentSnapshot else {
                return then(nil)
            }
            
            guard let data = doc.data() else {
                return then(nil)
            }
            
            if let id = data["ID"] as? String {
                let deleted = unsafeCastBool(data["deleted"])
                let orgID = unsafeCastString(data["orgID"])
                if deleted == false && orgID != "" {
                    let club = Club(at: id)
                    club.await()
                    return then(club)
                } else {
                    return then(nil)
                }
            } else {
                return then(nil)
            }
        }
    }
    
    // @use: get phone number
    static func generateFreshPhoneNumber( _ then: @escaping(String) -> Void){

        // punt and say one of these is new random #
        let c1 = randomPhoneNumber()
        let c2 = randomPhoneNumber()
        let c3 = randomPhoneNumber()

        Club.queryClub(at: c1){ club in
            if let _ = club {
                Club.queryClub(at: c2){ club in
                    if let _ = club {
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
    static func queryClub( at code: String?, _ then: @escaping(Club?) -> Void ){
        
        guard let code = code else { return then(nil) }
        
        AppDelegate.shared.fireRef?
            .collection("clubs")
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
                    Club.get(at: res[0] ){ club in then(club) }
                }
            }
    }
    
    
    static func rootRef( for uid : String? ) -> DocumentReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("clubs").document( uid )
    }
    
    
    static func viewRef( for uid: String? ) -> DocumentReference? {
        return Club.rootRef(for: uid)?.collection("stats").document("view")
    }


    static func statRef( for uid: String? ) -> DocumentReference? {
        return Club.rootRef(for: uid)?.collection("stats").document("aggregate")
    }

    
    static func followerCollectionRef( for uid: String? ) -> CollectionReference? {
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        return Club.rootRef(for: uid)?.collection("followers")
    }
    
    static func followerRef( for uid: String?, at userId: UserID? ) -> DocumentReference? {
        guard let uuid = userId else { return nil }
        if uuid == "" { return nil }
        return Club.followerCollectionRef(for: uid)?.document(uuid)
    }
    
    static func deckRef( for uid: String?, at id: String? ) -> DocumentReference? {
        guard let uid = uid else { return nil }
        guard let id = id else { return nil}
        if uid == "" || id == "" { return nil }
        return Club.rootRef(for: uid)?.collection("flash_card_deck").document(id)
    }
    
    
}

