//
//  User.swift
//  byte
//
//  Created by Xiao Ling on 5/18/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine


/*

 @Class: User instance for all users that is not me
 @States:
 
 @Methods [READ]:
 
 @Methods [WRITE]:

*/


class User : Sink, Equatable  {
    
    // uids
    var uid: UserID!
    var pushToken: PushToken?
        
    // renderable properites
    var name     : String?
    var bio      : String = ""
    var thumbURL : URL?
    var queries  : [String] = []
    var isPrivUser: Bool = false

    // search properites
    var phone: String?
    var email: String?
    var timeStampLatest : Int = ThePast()
    var timeStampCreated: Int = ThePast()
    
    // social stat
    var numFollowers: Int = 0
    var numFollowing: Int = 0
    var numViews    : Int = 0
    
    // social
    var tikTok    : String = ""
    var instagram : String = ""
    var twitter   : String = ""
    var linkedin  : String = ""
    var website   : String = ""
    
    // payment
    var total_sales_in_coins: Int = 0

    // sponsor logic
    var new_account: Bool = false
    var sponsor: User?
    var lineage: User?
    
    var sponsor_id = "" {
        didSet {
            if sponsor_id != "" {
                UserList.shared.pull(for: self.sponsor_id){(_,_,user) in
                    self.sponsor = user
                }
            }
        }
    }
    
    
    init( at userId: UserID ){
        self.uid = userId
    }
    
    // unique id
    var uuid : UniqueID {
        get { return unsafeCastString(self.uid) }
        set { return }
    }
    
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uid != nil && rhs.uid != nil
            && lhs.uid! == rhs.uid!
    }
        
    /*
     @Use: sync user w/ backend db.
           load all of user's playlists
    */
    func await(){
        if self.uuid == "" { return }
        awaitRemote()
    }    
    
    // @use: await all vertices incident on me
    // cache the results in the graph
    func awaitFull(){
        if self.uuid == "" { return }
        WhisperGraph.col()?
            .whereField("userIds", arrayContains: self.uuid)
            .getDocuments() { (querySnapshot, err) in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    WhisperGraph.shared.fetch(data: data)
                }
            }
    }
        
    
    func isMe() -> Bool {
        return self.uuid == UserAuthed.shared.uuid
    }
 
}


//MARK:- await stub

extension User {
    
    /*
     @Use: listen for user's data changes, and update them here
    */
    func awaitRemote(){

        guard AppDelegate.shared.onFire() else { return }
        
        if self.uuid == "" { return }
        
        let viewRef  = UserAuthed.viewRef(for: self.uuid)
        let rootRef  = UserAuthed.rootRef(for: self.uuid)
        //let sponsRef = UserAuthed.sponsorRef(for: self.uuid)
        //let statisticsRef = UserAuthed.statisticsRef(for: self.uuid)
        
        rootRef?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.isPrivUser = unsafeCastBool(data["isPrivUser"])
        }
        
        // parse view
        viewRef?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.parseView(data)
        }
        
        // parse query
        let queryRef = UserAuthed.queryRef(for: self.uuid)
        queryRef?.addSnapshotListener{ documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            if let qs = data["queries"] as? [String] { self.queries = qs }
        }
        /*// parse sponsors
        sponsRef?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.parseSponsor(data)
        }
        // parse social
        statisticsRef?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            // social stat
            self.numFollowers = unsafeCastIntToZero(data["numFollowers"])
            self.numFollowing = unsafeCastIntToZero(data["numFollowing"])
            self.numViews     = unsafeCastIntToZero(data["numViews"])
        }*/
    }


    /*
     @Use: parse user into client side object
    */
    private func parseView ( _ data: [String:Any] ){

        self.name      = unsafeCastString(data["name"])
        self.bio       = unsafeCastString(data["bio"])
        self.phone     = unsafeCastString(data["phone"])
        self.email     = unsafeCastString(data["email"])
        self.website   = unsafeCastString(data["website"])
        self.pushToken = data["pushNotificationToken"] as? String

        let small = unsafeCastString(data["profileImageSmall"])
        let prevThumb = self.thumbURL
        
        //images
        self.thumbURL = small == "" ? nil : URL(string: small)

        // push thumnbail into ImageLoader shared instance
        if ( self.thumbURL != nil && prevThumb != self.thumbURL ){
            let _ = ImageLoader.shared.loadImage(from: self.thumbURL!)
        }
        
        // social media profiles
        self.tikTok    = unsafeCastString(data["tikTok"])
        self.instagram = unsafeCastString(data["instagram"])
        self.twitter   = unsafeCastString(data["twitter"])
        self.linkedin  = unsafeCastString(data["linkedin"])

        // cache thumbnail immediately
        self.cacheImage()
        
    }
    
    // parse sponsorship
    private func parseSponsor ( _ data: [String:Any] ){
        self.sponsor_id = unsafeCastString(data["sponsor"])
        self.new_account = unsafeCastBool(data["new_account"])
    }

    
    // get amt of sales in coins
    func awaitBalance(){
        
        let ref = UserAuthed.paymentRef(for: self.uuid)
        
        ref?.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else { return }
                guard let data = document.data() as FirestoreData? else { return }
                self.total_sales_in_coins = unsafeCastIntToZero(data["total_sales_in_coins"])
        }
    }
    

    /*
     @Use: force load user' profile image
    */
    private func cacheImage(){
        if let small = thumbURL {
            let source = ImageLoader.shared.loadImage(from: small )
            let _ = source.sink { [weak self] image in return }
        }
    }
    
}


