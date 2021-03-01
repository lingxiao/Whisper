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
    
    func rmv(){

        let root = AppDelegate.shared.fireRef?.collection("users")
        root?.getDocuments() { (querySnapshot, err) in

            guard let docs = querySnapshot?.documents else { return }

            for doc in docs {
                guard let data = doc.data() as? FirestoreData else { continue }
                guard let uid = data["userID"] as? String else { continue }
                root?.document(uid).collection("followers").getDocuments() { (querySnapshot, err) in
                    guard let docs = querySnapshot?.documents else { return }
                    for doc in docs {
                        guard let data = doc.data() as? FirestoreData else { continue }
                        guard let id = data["userID"] as? String else { continue }
                        root?.document(uid).collection("followers").document(id).delete()
                    }
                }
            }
        }        
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

    
