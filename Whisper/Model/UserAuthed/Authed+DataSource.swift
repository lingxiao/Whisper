//
//  Authed+DataSource.swift
//  byte
//
//  Created by Xiao Ling on 6/9/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth
import UIKit



extension UserAuthed {
    
    /*
     @Use: update my user data from db
    */
    func awaitRemote(_ complete: @escaping (UserAuthed?,String) -> Void){

        guard let userID = Auth.auth().currentUser?.uid else {
            return complete(nil, "No userID")
        }

        guard AppDelegate.shared.onFire() else {
            return complete(nil, "Firebase not configured")
        }
        
        if userID == "" {
            complete(nil, "No userID")
        }
        
        let root       = UserAuthed.rootRef(for: userID)
        let queryRef   = UserAuthed.queryRef(for: userID)
        let viewRef    = UserAuthed.viewRef(for: userID)
        let sponsorRef = UserAuthed.sponsorRef(for: userID)
        let onboardRef = UserAuthed.onboardWalkThruRef(for: userID)

        root?.addSnapshotListener { documentSnapshot, error in
            // parse
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.isPrivUser = unsafeCastBool(data["isPrivUser"])
        }

        // parse sponsorship information
        sponsorRef?.addSnapshotListener{ documentSnapshot, error in
            
            // parse
            guard let document = documentSnapshot else {
                return complete(nil, "Document failed to deocde")
            }
            
            guard let data = document.data() as FirestoreData? else {
                return complete(nil, "Document failed to deocde")
            }
            
            self.sponsor_id = unsafeCastString(data["sponsor"])
            self.sponsor_club = unsafeCastString(data["sponsor_club"])

            UserList.shared.pull(for: self.sponsor_id ){ (_,_,sponsor) in

                self.sponsor = sponsor

                // check if this is a new account and then broadcast
                if let new_account = data["new_account"] as? Bool {
                    self.new_account = new_account
                }
                
                return complete( self, "loaded" )
            }
        }
        
        viewRef?.addSnapshotListener{ documentSnapshot, error in
            
            // parse
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }

            // load view elements
            self.name  = unsafeCastString(data["name"])
            self.bio   = unsafeCastString(data["bio"])
            self.email = unsafeCastString(data["email"])
            self.numEdits = unsafeCastIntToZero(data["numEdits"])
            self.current_org_id = unsafeCastString(data["current_org_id"])
                
            // load profile image URL
            let small  = unsafeCastString(data["profileImageSmall"])
            let medium = unsafeCastString(data["profileImageMedium"])
            let large  = unsafeCastString(data["profileImageLarge"])

            let prevURL    = self.thumbURL
            self.thumbURL  = small  == "" ? nil : URL(string:small )
            self.mediumURL = medium == "" ? nil : URL(string:medium)
            self.fullURL   = large  == "" ? nil : URL(string:large )
                
            if ( prevURL != self.thumbURL){  self.cacheImage() }
        }
        
        queryRef?.addSnapshotListener{ documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            if let qs = data["queries"] as? [String] { self.queries = qs }
        }
        
        onboardRef?.addSnapshotListener{ documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.did_tag_deck_1st_time = unsafeCastBool( data["did_tag_deck"])
            self.did_drag_audio_room = unsafeCastBool(data["did_drag_audio_room"])
            self.did_drag_deck = unsafeCastBool(data["did_drag_deck"])
            self.did_switch_rooms = unsafeCastBool(data["did_switch_rooms"])
            self.did_drag_news_feed = unsafeCastBool(data["did_drag_news_feed"])
            self.did_consent_to_emphemeral_club = unsafeCastBool(data["did_consent_to_emphemeral_club"])
            self.didSyncContacts = unsafeCastBool(data["didSyncContacts"])
        }
    }

    // get admin resource
    func awaitAdminResource(){
        
        // get admin url and force load
        // https://apps.apple.com/us/app/id1512695945
        AppDelegate.shared.fireRef!
            .collection("adminResource")
            .document( "profile" )
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else { return }
                guard let data = document.data() as FirestoreData? else { return }
                let url = unsafeCastString(data["installURL"])
                self.installURL = URL(string:url)
        }
    }
    
    
    /*
     @Use: begin caching user's image immediately
    */
    func cacheImage(){

        if let url = self.thumbURL {
            let source = ImageLoader.shared.loadImage(from: url)
            let _ = source.sink { [unowned self] image in return }
        }
        /*if let url = self.mediumURL {
            let _ = ImageLoader.shared.loadImage(from: url)
        }
        if let url = self.fullURL {
            let _ = ImageLoader.shared.loadImage(from: url)
        }*/
    }
}

