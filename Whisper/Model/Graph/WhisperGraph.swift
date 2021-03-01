//
//  WhisperGraph.swift
//  byte
//
//  Created by Xiao Ling on 1/22/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth


//MARK:- graph stub

class WhisperGraph : Sink {
    
    static let shared = WhisperGraph()
    private var cached: [String:WhisperEdge] = [:]
    
    init(){}

    static func col() -> CollectionReference? {
        return AppDelegate.shared.fireRef?.collection("graph")
    }

    static func ref( at uid: String? ) -> DocumentReference? {
        guard let uid = uid else { return nil }
        return WhisperGraph.col()?.document( uid )
    }
    
    func await(){
        
        guard AppDelegate.shared.onFire() else { return }
        let uid = UserAuthed.shared.uuid
        if uid == "" { return }
        
        WhisperGraph.col()?
            .whereField("userIds", arrayContains: uid)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                for doc in documents {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    self.fetch(data: data)
                }
            }
    }
    
    // fetch from db
    public func fetch( data: FirestoreData? ){
        guard let data = data else { return }
        guard let id = data["uuid"] as? String else { return }
        if self.cached[id] == nil {
            let edge = WhisperEdge(at: id)
            edge.await()
            self.cached[id] = edge
        }
    }
}

//MARK:- read

extension WhisperGraph {

    // @use: get persmission, if not found return nil
    func get( for uid: UserID? ) -> WhisperEdge? {
        guard let uid = uid else { return nil }
        let vals = Array(cached.values).filter{ $0.userIds.contains(uid) }
        return vals.count > 0 ? vals[0] : nil
    }
    
    // get all edges incident on user
    func getIncident( on user: User? ) -> [WhisperEdge] {
        guard let user = user else { return [] }
        let id = user.uuid
        return Array(cached.values).filter{ $0.userIds.contains(id) }
    }
    
    // get all followers of this user
    func getFollowers( of user: User?, _ then: @escaping ([User]) -> Void) {
        
        guard let user = user else { return then([]) }

        let vals = Array(cached.values).filter{ $0.isFollowing(user) }
        var uids: [UserID] = []
        for v in vals {
            uids.append(contentsOf: v.userIds)
        }
        let sm = Array(Set(uids)).filter{ $0 != user.uuid}
        UserList.shared.batchWith(these: sm){ users in then(users) }
    }
    
    // get everyone following this user
    func getFollowing( for user: User?, _ then: @escaping ([User]) -> Void) {

        guard let user = user else { return then([]) }

        let vals = Array(cached.values).filter{ $0.isFollowedBy(user) }
        var uids: [UserID] = []
        for v in vals {
            uids.append(contentsOf: v.userIds)
        }
        let sm = Array(Set(uids)).filter{ $0 != user.uuid}
        UserList.shared.batchWith(these: sm){ users in then(users) }
    }
    
    // check if I blocked this user
    func iDidBlock( this user: User? ) -> Bool {
        
        guard let user = user else { return false }

        if user.isMe() { return false }
        
        if let pair = get(for:user.uuid) {
            if iAmUserA(with: user) {
                return pair.A_blocked_B
            } else {
                return pair.B_blocked_A
            }
        } else {
            return false
        }
    }
    
    // check if this user blocked me
    func didBlockMe( this user: User? ) -> Bool {
        guard let user = user else { return false }
        if user.isMe() { return false }
        if let pair = get(for:user.uuid) {
            if iAmUserA(with: user) {
                return pair.B_blocked_A
            } else {
                return pair.A_blocked_B
            }
        } else {
            return false
        }
    }

    func iAmFollowing( this user: User? ) -> Bool {
        guard let user = user else { return false }
        if user.isMe() { return false }
        if let pair = get(for:user.uuid) {
            if iAmUserA(with: user) {
                return pair.A_follow_B
            } else {
                return pair.B_follow_A
            }
        } else {
            return false
        }
    }
    
    func isFollowingMe( this user: User? ) -> Bool {
        guard let user = user else { return false }
        if user.isMe() { return false }
        if let pair = get(for:user.uuid) {
            if iAmUserA(with: user) {
                return pair.B_follow_A
            } else {
                return pair.A_follow_B
            }
        } else {
            return false
        }
    }
}

//MARK:- write

extension WhisperGraph {
    
    // @use: log frequency in which I speak to `users`
    func iSpoke(to users: [User] ){

        let other_users = users.filter{ $0.isMe() == false }
        for user in other_users {
            if let pair = get(for: user.uuid) {
                if iAmUserA(with: user) {
                    let res : FirestoreData = ["A_talk2_B":pair.A_talk2_B+1]
                    WhisperGraph.ref(at: pair.uuid)?.updateData(res){ e in return }
                } else {
                    let res : FirestoreData = ["B_talk2_A":pair.B_talk2_A+1]
                    WhisperGraph.ref(at: pair.uuid)?.updateData(res){ e in return }
                }
            } else {
                if var res = makeBlankPair(with: UserList.shared.yieldMyself(), and: user){
                    if iAmUserA(with: user) {
                        res["A_talk2_B"] = 1
                    } else {
                        res["B_talk2_A"] = 1
                    }
                    if let id = res["uuid"] as? String {
                        WhisperGraph.ref(at: id)?.setData(res){ e in return }
                    }
                }
            }
        }
    }
    
    // @use: I follow this user
    func follow( user: User?, isFollowing: Bool ){

        guard let user = user else { return }
        if user.isMe() { return }

        if let pair = get(for: user.uuid) {
            
            if iAmUserA(with: user) {
                var res : FirestoreData = ["A_follow_B":isFollowing]
                if isFollowing {
                    res["A_blocked_B"] = false
                }
                WhisperGraph.ref(at: pair.uuid)?.updateData(res){ e in return }
            } else {
                var res : FirestoreData = ["B_follow_A":isFollowing]
                if isFollowing {
                    res["B_blocked_A"] = false
                }
                WhisperGraph.ref(at: pair.uuid)?.updateData(res){ e in return }
            }
            
        } else {
            
            guard var res = makeBlankPair(with: UserList.shared.yieldMyself(), and: user) else {
                return
            }
            
            if iAmUserA(with: user) {
                res["A_follow_B"] = isFollowing
            } else {
                res["B_follow_A"] = isFollowing
            }
            
            if let id = res["uuid"] as? String {
                WhisperGraph.ref(at: id)?.setData(res){ e in return }
            }
            
        }
        
    }
    
    //Use: I block this user
    func block( user: User?, blocking: Bool ){
        
        guard let user = user else { return }
        if user.isMe() { return }
        
        if let pair = get(for: user.uuid) {
            
            if iAmUserA(with: user) {
                var res : FirestoreData = ["A_blocked_B":blocking]
                if blocking {
                    res["A_follow_B"] = false
                }
                WhisperGraph.ref(at: pair.uuid)?.updateData(res){ e in return }
            } else {
                var res : FirestoreData = ["B_blocked_A":blocking]
                if blocking {
                    res["B_follow_A"] = false
                }
                WhisperGraph.ref(at: pair.uuid)?.updateData(res){ e in return }
            }
            
        } else {
            
            guard var res = makeBlankPair(with: UserList.shared.yieldMyself(), and: user) else {
                return
            }
            
            if iAmUserA(with: user) {
                res["A_blocked_B"] = blocking
            } else {
                res["B_blocked_A"] = blocking
            }
            
            if let id = res["uuid"] as? String {
                WhisperGraph.ref(at: id)?.setData(res){ e in return }
            }
            
        }
        
    }
    

}
