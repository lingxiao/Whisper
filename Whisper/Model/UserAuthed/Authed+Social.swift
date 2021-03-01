//
//  Authed+Social.swift
//  byte
//
//  Created by Xiao Ling on 6/29/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


//MARK:- social boolean

extension UserAuthed {
    
    // @use: check if I am followed by this person
    func isFollowedBy( at uid: UserID? ) -> Bool {
        if let user = UserList.shared.get(uid) {
            return WhisperGraph.shared.isFollowingMe(this: user)
        } else {
            return false
        }

    }

    // check if i am following this user
    func iAmFollowing( at uid: UserID? ) -> Bool {
        if let user = UserList.shared.get(uid) {
            return WhisperGraph.shared.iAmFollowing(this: user)
        } else {
            return false
        }
    }

}


//MARK:- social setter

extension UserAuthed {
    
    // @Use: i follow user
    func follow( _ user: User? ){
        guard let user = user else { return }
        WhisperGraph.shared.follow(user: user,isFollowing:true)
        setAlert( for: user.uuid, kind: .follow )
    }
    
    
    // @Use: i unfollow user
    func unfollow( _ user: User? ){
        guard let user = user else { return }
        WhisperGraph.shared.follow(user: user,isFollowing:false)
    }
    
   
    // @use: flag this user
    func flag( _ uid : String? ) {
        
        guard let uid = uid else { return }
        if uid == self.uuid { return }

        // record transation
        let trans_id = UUID().uuidString

        let record : FirestoreData = [
            "uuid": trans_id,
            "flagged": uid,
            "flagged_by": self.uuid,
            "timeStamp": now(),
            "userIds": [self.uuid, uid ]
        ]
                
        AppDelegate.shared
            .fireRef?
            .collection("log_flag")
            .document(trans_id)
            .setData( record ){ err in return }
        
    }
    
    

}
