//
//  User+Social.swift
//  byte
//
//  Created by Xiao Ling on 7/3/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation



//MARK: - read users

extension User {
    
    // @use: if i am new user
    func iamNew() -> Bool {
        return now() - timeStampCreated < 60*60*24*7
    }

    
    //@Use: get all speakers whomst this `user` instance have interacted with
    // narrow the set to the organizations the authenticated user belongs to
    func fetchPeopleISpokeTo( _ then: @escaping ([User]) -> Void ){
        
        // get all the organziations that I belong to
        let orgs = ClubList.shared.fetchNewsFeed().map{ $0.0 }
        
        // get all people from this org
        var users_i_know : [UserID] = []
        for org in orgs {
            let users = org.getRelevantUsers()
            users_i_know.append(contentsOf: users.map{$0.uuid})
        }
        users_i_know = Array(Set(users_i_know))
        
        // get all edges incident on me, sorted by frequency in which I spoke to
        // filter out anyone whomst I have not interacted with
        var uids = WhisperGraph.shared
            .getIncident(on:self)
            .filter{ $0.freqSpeaking() > 0 }
            .sorted{ $0.freqSpeaking() > $1.freqSpeaking() }
            .map{ $0.userIds.filter{ $0 != self.uuid } }
            .filter{ $0.count > 0 }
            .map{ $0[0] }
            .filter{ users_i_know.contains($0) }
        
        uids = Array(Set(uids))
        
        // get the users instances and output value
        UserList.shared.batchWith(these: uids){ users in
            then(users)
        }
    }
    
    // @use: return 2-directional following
    func fetchFriends( _ then: @escaping ( [User] ) -> Void ) {
        WhisperGraph.shared.getFollowers(of: self){ followers in
            WhisperGraph.shared.getFollowing(for: self){ following in
                let res = followers.filter{ following.contains($0) }
                then(res)
            }
        }
    }

}

//MARK:- boolean checks

extension User {
    
    /*
     @Use: check if I match this query
     */
    func match(query:String?) -> Bool {
        guard let xs = query else { return false }
        let patterns = generateSearchQueriesForUser(name: xs, email: "")
        let my_patts = generateSearchQueriesForUser(name: get_H1(), email: "")
        let hat = my_patts.filter { patterns.contains($0) }
        return hat.count > 0
    }
    
    func matchAny( _ query: [String] ) -> Bool {
        
        var res : Bool = false
        
        for q in query {
            res = res || match(query:q)
        }
        
        return res
    }


    /*
     @Use: given phone #s and email from address book, check if
           we match this one
     */
    func matchAdressBook( phone: [String], email: [String]) -> Bool{
        
        if ( self.phone == nil || self.email == nil ){ return false }

        return phone.contains(self.phone!) || email.contains(self.email!)
    }

}
