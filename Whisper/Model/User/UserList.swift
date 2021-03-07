//
//  UserList.swift
//  byte
//
//  Created by Xiao Ling on 5/18/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase



/*
 @Class: Chat priority queue singelton. observes firebase database for
            * chats I am scheduled to speak/observe
            * chats I am in
            * chats I have existed
 @Use: load and cache user data. to be used sparingly for view display only
 @Methods:
    [READ] 
    [WRITE]
*/



//MARK:- class declaration

class UserList: Sink {

    /// @use: global contact list declaration and setup
    static let shared = UserList()
    
    // @Use: store all my friends
    var cached: [UserID:User] = [:]
    var addressBook : [UserID:User] = [:]
    var admin: User?
    
    init(){}
    
    /*
     @Use: when a new contact is created, pull user from
           db and cache
     */
    func await(){
        let _ = self.yieldMyself()
        yieldAdmin(){ _ in return }
    }
    
    
    /*
     @Use: current authed user as User instance
     */
    func yieldMyself() -> User? {
        
        let uid = UserAuthed.shared.uuid
        if uid == "" { return nil }

        if let user = cached[uid] {
            return user
        } else {
            let me = User(at: uid )
            me.await()
            self.cached[uid] = me
            return me
        }
    }
    
    
    // @Use: yield admin
    func yieldAdmin( _ then: @escaping(User?) -> Void ){
        
        if let admin = self.admin {

            return then(admin)

        } else {
        
            AppDelegate.shared.fireRef?
                .collection("adminResource")
                .document( "adminUser" )
                .getDocument{( documentSnapshot, error) in
                    if ( error != nil || documentSnapshot == nil){ return then(nil) }
                    guard let doc = documentSnapshot else { return then(nil) }
                    guard let data = doc.data() else { return then(nil) }
                    let id = unsafeCastString(data["userID"])
                    self.pull(for: id){(_,_,admin) in
                        self.admin = admin
                        then(admin)
                    }
                }
        }
    }
    
    /*
     @Use: on load addres book, find all users in database from address book
           this is to present to the user as sugested people to call
           Note you will find your self from this search as well
    */
    func onloadFromAddressBook( with contacts: [PhoneContact] ){
        
        for contact in contacts {

            var query : [String] =  contact.phoneNumber
             query.append( contentsOf:  contact.email )
            
            // this will grab all users in db matching phonenumber OR email
            self.filter(on: query ){(succ,msg,res) in

                if ( !succ || res.count == 0 ){ return }

                for user in res {

                    self.addressBook[user.uuid] = user
                    
                    // Follow this user
                    /*if !UserAuthed.shared.iAmFollowing(at: user.uuid){
                        PlayList.followEach(user.uuid)
                    }*/
                    
                    // This creates a group with each one
                    //GroupList.shared.syncAddressBookEach(with: user)
                }
            }
        }
    }
    
}

    

//MARK: - READ- 

extension UserList {
    

    func get( _ uid : UserID? ) -> User? {
        
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        
        if let user = cached[uid] {
            return user
        } else {
            return addressBook[uid]
        }
        
    }
    
    //@Use: get user from db if availabe
    func pull( for uid : UserID?,_ complete: @escaping (Bool,String,User?) -> Void){
        
        guard let uid = uid else {
            return complete(false, "no UID specified", nil)
        }
        
        if uid == "" {
            return complete(false, "no UID specified", nil)
        }

        // pull from cache if possible
        if let res = get(uid) {
            return complete(true, "Cached", res)
        }

        // check i can pull from server
        guard AppDelegate.shared.onFire() else {
            return complete(false, "Failed to get reach firebase backend", nil)
        }
        
        // fetch from server
        AppDelegate.shared.fireRef!
            .collection("users")
            .document( uid )
            .getDocument { documentSnapshot, error in
                
                if ( error != nil || documentSnapshot == nil){
                    complete(false, "Failed to get reach firebase backend", nil)
                    return
                }
                
                guard let doc = documentSnapshot else {
                    complete( false, "failed to snap document", nil )
                    return
                }
                
                guard let data = doc.data() else {
                    complete( false, "failed to decode document", nil )
                    return
                }
                
                if let user = self.parse( from: data ) {
                    self.cached[user.uuid] = user
                    complete( true, "success", user )
                } else {
                    complete(false,"failed to decode user", nil)
                }
            }
                

    }
    

    /*
     @Use: fetch all user and run complete when done
     */
    func batchWith( these uids: [UserID], complete: @escaping ([User]) -> Void ){
        
        var res : [User] = []
        let dispatch = DispatchGroup()

        for uid in uids {
            
            autoreleasepool{ // memory management

                dispatch.enter()
                UserList.shared.pull(for: uid){(succ,msg,usr) in
                    if (usr != nil){ res.append(usr!) }
                    dispatch.leave()
                }
            }
        }
        
        dispatch.notify(queue: .main) { complete(res) }
    }
    
    /*
     @use: parse user, set delegate and cache
     */
    func parse( from data: FirestoreData ) -> User? {

        guard let uid = data["userID"] as? String else { return nil }
        
        // if user already cached, do not push
        // then hook user to backdend database
        if let user = get( uid ){
            return user
        } else {
            let user = User( at: uid )
            user.await()
            self.cached[uid] = user
            return user
        }
    }

    /*
     @Use: query the database for users matching `match` query
    */
    func filter( on match : [String],_ complete: @escaping CompletionUserList){

        guard AppDelegate.shared.onFire() else {
            return complete( false, "firebase not configured", [])
        }
        
        if ( match.count == 0 ){
            return complete( false, "empty query", [])
        }
            
        // firebase limit query to 10 elements, so we have to aggresively prune
        let match_small = Array(match.prefix(10))

        AppDelegate.shared.fireRef!
            .collection("user_queries")
            .whereField("queries", arrayContainsAny: match_small)
            .getDocuments() { (querySnapshot, err) in

                guard let docs = querySnapshot?.documents else {
                    complete(false, "failed to decode db snapshot", [])
                    return
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
                    complete( true, "done", users )
                }
        }
    }
    
    /*
     @Use: query the database for users matching `match` query
    */
    func filterForInviteCode( with code: String?,_ then: @escaping ([User]) -> Void){
        
        guard let code = code else { return then([]) }

        guard AppDelegate.shared.onFire() else {
            return then([])
        }

        AppDelegate.shared.fireRef?
            .collection("users")
            .whereField("outvite_code", isEqualTo: code)
            .getDocuments() { (querySnapshot, err) in

                guard let docs = querySnapshot?.documents else {
                    return then([])
                }

                var res : [User] = []

                for doc in docs {
                    
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let uid = data["userID"] as? String else { continue }
                    
                    if let user = self.get(uid) {
                        res.append( user )
                    } else {
                        if let new_user = self.parse( from: data ){
                            res.append(new_user)
                        }
                    }
                }
                
                then(res)
                return
        }
    }

}
