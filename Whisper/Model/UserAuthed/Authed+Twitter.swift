//
//  Authed+Twitter.swift
//  byte
//
//  Created by Xiao Ling on 8/29/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


extension UserAuthed {
    
    // @use: get my twitter info
    func awaitTwiter(){

        AppDelegate.shared.fireRef!
            .collection("users_twitter")
            .document( self.uuid )
            .addSnapshotListener { documentSnapshot, error in

                // parse
                guard let document = documentSnapshot else { return }
                guard let data = document.data() as FirestoreData? else { return }

                if let tok = data["accessToken"] as? String {
                    if let sec = data["secret"] as? String {
                        
                        if tok != "" && sec != "" {
                        self.did_link_twitter = true
                        }
                    }
                }
        }
    }
    
    /*
     @use: save twitter
     */
    func saveTwitter(
          secret: String?
        , accessToken: String?
        , screen_name: String = ""
        , twitterId: Int = 0
        , _ then: @escaping (Bool) -> Void
    ){
        
        guard let sec = secret else { return then(false) }
        guard let tok = accessToken else { return then(false) }
        
        let blob : FirestoreData = [
              "userId": self.uuid
            , "secret": sec
            , "accessToken": tok
            , "screen_name": screen_name
            , "twitterId": twitterId
            , "timeStamp": now()
        ]

        AppDelegate.shared.fireRef?.collection("users_twitter")
            .document(self.uuid)
            .setData( blob ){ err in
                if let _ = err {
                    then(false)
                } else {
                    then(true)
                }
        }
        
    }
    
    //@Use: mark twitter as unlinked
    func unlinkTwitter(){
        
        func step( blob : FirestoreData? ) -> FirestoreData? {
            guard var update = blob else { return nil }
            update["secret"] = ""
            update["accessToken"] = ""
            return update
        }
    }
    
    /*
     @use: send tweet
     */
    func sendTweet( with str : String = "", for host: User?, _ then: @escaping (Bool,String) -> Void ){
        
        guard self.did_link_twitter else {
            return then(false, "Your twitter account is not linked")
        }
        
        var hid = ""
        if let host = host {
            hid = host.uuid
        }
        
        let blob : FirestoreData = [
              "userId": self.uuid
            , "timeStamp": now()
            , "message" : str
            , "hostId"  : hid
        ]

        AppDelegate.shared.fireRef?.collection("log_tweet")
            .document(self.uuid)
            .setData( blob ){ err in
                if let _ = err {
                    then(false, "We failed to invoke twitter")
                } else {
                    then(true, "Success!")
                }
        }
        
        
    }
    
}
