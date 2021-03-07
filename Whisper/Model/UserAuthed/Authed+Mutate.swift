//
//  Authed+Mutate.swift
//  byte
//
//  Created by Xiao Ling on 6/9/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth


extension UserAuthed {
    
    func sceneDidDisconnect(){
        for club in ClubList.shared.whereAmILive() {
            club.exitAllRooms(hard: true)
        }
    }
    
    /*
     @Use: save profile image
     */
    func changeImage(to image: UIImage?, _ complete: @escaping Completion){
        
        guard let img = image else {
            complete(false, "No image found")
            return
        }

        guard AppDelegate.shared.canStore() else {
            complete(false, "No storage bucket found")
            return
        }                       

        let large  = img.jpegData(compressionQuality: 1.00 )
        let small  = img.jpegData(compressionQuality: 0.10)

        UserAuthed.uploadImage( to: "\(self.uuid)/profileImageSmall.jpg", with: small ){ (succ, url) in
            guard let ref = UserAuthed.rootRef(for: self.uuid) else { return }
            ref.updateData( ["profileImageSmall":url] ){ e in return }
        }

        UserAuthed.uploadImage( to: "\(self.uuid)/profileImageLarge.jpg", with: large ){ (succ, url) in
            guard let ref = UserAuthed.rootRef(for: self.uuid) else { return }
            ref.updateData( ["profileImageLarge":url] ){ e in return }
        }
        
        complete(true, "success")
    }
    
   
    /*
     @Use: change user's  name, and update query
    */
    func setName( _ str: String? ){

        guard let str = str else { return}
        if str == "" { return }
        guard let ref = UserAuthed.rootRef(for: self.uuid) else { return }
        
        // 3 edits max
        if self.numEdits > MAX_NAME_EDITS { return }
        let num = str == self.name ? self.numEdits : self.numEdits + 1
        
        // batch updates
        let batch = AppDelegate.shared.fireRef?.batch()
        let queries = generateSearchQueriesForUser(name: str, email: (self.name ?? ""))
        let blob : FirestoreData = ["name": str, "numEdits": num ]
        batch?.updateData(blob, forDocument: ref)
        
        if let q_ref = UserAuthed.queryRef(for: self.uuid){
            let qlob : FirestoreData = ["queries": queries, "userID": self.uuid, "timeStamp": now() ]
            batch?.updateData(qlob, forDocument: q_ref)
        }
        batch?.commit(){e in return }
    }
    
    
    func setBio( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["bio":str]){e in return }
    }
    
    func setCurrentOrg( to str: String? ){
        guard let str = str else { return }
        if str == "" { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["current_org_id":str]){e in return }
    }
    
    func setIG( _ ig: String? ){
        guard let ig = ig else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["instagram":ig]){e in return }
    }
    
    func setTikTok( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["tikTok":str]){e in return }
    }
    
    func setLinkedIn( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["linkedin":str]){e in return }
    }
    
    func setWebsite( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["website":str]){e in return }
    }
    

    func setTwitter( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["twitter":str]){e in return }
    }

    func setYoutube( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["youtube":str]){e in return }
    }

    func setSpotify( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["spotify":str]){e in return }
    }
    
    func setLinkedin( _ str: String? ){
        guard let str = str  else { return }
        UserAuthed.rootRef(for: self.uuid)?.updateData(["linkedin":str]){e in return }
    }
    
    func didTagDeck1stTime(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["did_tag_deck":false])
    }

    
    /*
     @Use: change firebase push notification token. update time. set call to active
     */
    func changeToken( to tok : String?, _ complete: @escaping (Bool, String) -> Void ){
        
        guard let tok = tok else { return complete(false, "invalid token")  }
        
        self.notification_token = tok
        
        guard let ref = UserAuthed.rootRef(for: self.uuid) else {
            return complete(false,"no-ref")
        }
        
        ref.updateData(["pushNotificationToken": tok]){ e in
            if let e = e {
                complete(false, "\(e.localizedDescription)")
            } else {
                complete(true, "")
            }
        }
    }
    
}

