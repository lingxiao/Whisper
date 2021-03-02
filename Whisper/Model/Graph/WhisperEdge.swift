//
//  WhisperEdge.swift
//  byte
//
//  Created by Xiao Ling on 1/23/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth

//MARK:- constants


func makeBlankPair( with userA: User?, and userB: User? ) -> FirestoreData? {
    
    guard let userA = userA else { return nil }
    guard let userB = userB else { return nil }
    if userA.uuid == userB.uuid { return nil }
    
    let ids = sortIds(ids: [userA.uuid,userB.uuid])
    let uuid : String = "\(ids[0])_\(ids[1])"
    
    let p : FirestoreData = [
        "uuid"  : uuid,
        "userA" : ids[0],
        "userB" : ids[1],
        "userIds": ids,
        "A_blocked_B": false,
        "B_blocked_A": false,
        "A_follow_B" : false,
        "B_follow_A" : false,
        "A_talk2_B"  : 0,
        "B_talk2_A"  : 0,
        "timeStamp"  :  now()
    ]
    
    return p
}


func iAmUserA( with user: User? ) -> Bool {
    guard let user = user else { return false }
    let ids = sortIds(ids: [UserAuthed.shared.uuid,user.uuid])
    return ids[0] == UserAuthed.shared.uuid
}


//MARK: - edge class

class WhisperEdge : Sink {
    
    var uid: String = ""

    var userA: String = ""
    var userB: String = ""
    var userIds: [String] = []
    var A_blocked_B: Bool = false
    var B_blocked_A: Bool = false
    var A_follow_B : Bool = false
    var B_follow_A : Bool = false
    var A_talk2_B  : Int = 0
    var B_talk2_A  : Int = 0
    var timeStamp  : Int = 0

    
    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }

    init( at id: String! ){
        self.uid = id
    }
    
    func incident( on uid: String? ) -> Bool {
        if let uid = uid {
            return self.userIds.contains(uid)
        } else {
            return false
        }
    }
    
    func isFollowing( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        if self.userA == user.uuid {
            return B_follow_A
        } else if userB == user.uuid {
            return A_follow_B
        } else {
            return false
        }
    }
    
    func isFollowedBy( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        if self.userA == user.uuid {
            return A_follow_B
        } else if userB == user.uuid {
            return B_follow_A
        } else {
            return false
        }
    }
    
    func isBlocking( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        if self.userA == user.uuid {
            return B_blocked_A
        } else if userB == user.uuid {
            return A_blocked_B
        } else {
            return false
        }
    }
    
    func isBlockedBy( _ user: User? ) -> Bool {
        guard let user = user else { return false }
        if self.userA == user.uuid {
            return A_blocked_B
        } else if userB == user.uuid {
            return B_blocked_A
        } else {
            return false
        }
    }
    
    func freqSpeaking() -> Int {
        return self.A_talk2_B + B_talk2_A
    }

    
    func await(){
        if self.uuid == "" { return }
        WhisperGraph.ref(at: self.uuid)?.addSnapshotListener{ documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            
            guard let uidA = data["userA"] as? String else { return }
            guard let uidB = data["userB"] as? String else { return }
            
            let prev_A_blocked_B = self.A_blocked_B
            let prev_B_blocked_A = self.B_blocked_A
            let prev_A_follow_B = self.A_follow_B
            let prev_B_follow_A = self.B_follow_A
                        
            self.userA       =  uidA
            self.userB       =  uidB
            self.userIds     =  [uidA,uidB]
            self.A_blocked_B =  unsafeCastBool(data["A_blocked_B"])
            self.B_blocked_A =  unsafeCastBool(data["B_blocked_A"])
            self.A_follow_B  =  unsafeCastBool(data["A_follow_B"])
            self.B_follow_A  =  unsafeCastBool(data["B_follow_A"])
            self.A_talk2_B   =  unsafeCastIntToZero(data["A_talk2_B"])
            self.B_talk2_A   =  unsafeCastIntToZero(data["B_talk2_A"])
            self.timeStamp   =  unsafeCastInt(data["timeStamp"])
            
            // post i have been blocked
            if prev_A_blocked_B != self.A_blocked_B {
                if UserAuthed.shared.uuid == self.userB  && self.A_blocked_B {
                    postDidBlockMe(userID: uidA)
                }
            }
            if prev_B_blocked_A != self.B_blocked_A {
                if UserAuthed.shared.uuid == self.userA && self.B_blocked_A {
                    postDidBlockMe(userID: uidB)
                }
            }
            
            // update action from me: block
            if self.incident(on: UserAuthed.shared.uuid) && (prev_A_blocked_B != self.A_blocked_B || prev_B_blocked_A != self.B_blocked_A) {
                postIdidBlock(userID: uidA)
                postIdidBlock(userID: uidB)
            }

            // update action from me: follow
            if self.incident(on: UserAuthed.shared.uuid) && (prev_A_follow_B != self.A_follow_B || prev_B_follow_A != self.B_follow_A) {
                postDidFollow(userID: uidA)
                postDidFollow(userID: uidB)
            }
        }
    }
}


