//
//  FlashCardDeck+Render.swift
//  byte
//
//  Created by Xiao Ling on 1/10/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



//MARK:- READ -

extension FlashCardDeck {

    func getCards() -> [FlashCard] {
        return Array(FlashCardCache.shared.cards.values)
            .filter{ $0.deckID == self.uuid }
            .sorted{ $0.timeStamp > $1.timeStamp }
    }

    func getLatestCard() -> FlashCard? {
        var xs = getCards()
        xs.sort{ $0.timeStamp > $1.timeStamp }
        return xs.count > 0 ? xs[0] : nil
    }

    func getCurrentCard( _ then: @escaping(FlashCard?) -> Void){

        if self.currentCardID != "" {
            FlashCardCache.shared.get(at: self.currentCardID){ card in
                then(card)
            }
        } else {
            let cards = getCards()
            if cards.count > 0 {
                then(cards[0])
            } else {
                then(nil)
            }
        }

    }

    func getCreator( _ then: @escaping(User?) -> Void){
        UserList.shared.pull(for: self.createdBy){(_,_,user) in
            return then(user)
        }
    }

    func isMine() -> Bool {
        return UserAuthed.shared.uuid == self.createdBy
    }


    func iCanEdit() -> Bool {

        let uid = UserAuthed.shared.uuid
        let homeClub = ClubList.shared.clubs[self.homeClubID]

        let blockedMe: Bool = WhisperGraph.shared.didBlockMe(this: self.creator)
        
        switch self.perm {
            case .openView_openEdit:
                return blockedMe ? false : true
            case .openView_groupEdit:
                let b1 = createdBy == uid
                if let club = homeClub {
                    return club.getMembers().map{ $0.uuid } .contains( uid )
                } else {
                    return b1
                }
            case .openView_creatorEdit:
                return createdBy == uid
            case .groupView_groupEdit:
                let b1 = createdBy == uid
                if let club = homeClub {
                    return club.getMembers().map{ $0.uuid } .contains( uid )
                } else {
                    return b1
                }
            case .groupView_creatorEdit:
                return createdBy == uid
            case .closed:
                return createdBy == uid
        }
    }
    

    func clubCanView( at club: Club? ) -> Bool {

        let only : [CardDeckPrivacy]  = [.groupView_groupEdit,.groupView_creatorEdit, .closed]

        guard let club = club else {
            return only.contains(self.perm) == false
        }
        
        if only.contains(self.perm) {
            return club.uuid == self.homeClubID 
        } else {
            return true
        }
    }
    
    func anyoneCanView() -> Bool {
        let only : [CardDeckPrivacy]  = [.openView_groupEdit, .openView_openEdit, .openView_creatorEdit ]
        return only.contains(self.perm)
    }

    func didTag( by club: Club? ){
        guard let club = club else { return }
        FlashCardDeck.tagRef(for: self.uuid, at: club.uuid)?.setData([
            "clubID": club.uuid,
            "userID": UserAuthed.shared.uuid,
            "timeStamp": now()
        ])
        FlashCard.rootRef(for: self.uuid)?.updateData(["numTags": self.numTags + 1]){ e in return }
    }
        
    func didUntag(by club: Club? ){
        guard let club = club else { return }
        FlashCardDeck.tagRef(for: self.uuid, at: club.uuid)?.delete()
        let k = self.numTags - 1 >= 0 ? self.numTags - 1 : 0
        FlashCard.rootRef(for: self.uuid)?.updateData(["numTags": k]){ e in return }
    }

}


//MARK:- render -

extension FlashCardDeck : Renderable {

    func get_H1() -> String {
        return self.name
    }
    
    func get_H2() -> String {
        return self.creator?.get_H1() ?? ""
    }
    
    func fetchThumbURL() -> URL? {
        return self.imgURL
    }
    
    func match(query: String?) -> Bool {
        return false
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    
    func get_history() -> String {
        let res = Array(self.checkin_history.values)
        let n = res.count
        let m = res.filter{ deckAudienceIsHere(for:$0) }.count
        let prefix = n > 1 ? "\(n.formatUsingAbbrevation()) views. " : ""
        let suffix = m > 1 ? "\(m.formatUsingAbbrevation()) are here right now" : "You just checked in, tap to see more"
        return "\(prefix)\(suffix)"
    }
    
    func getPreview( _ then: @escaping(FlashCard?) -> Void ) {
        
        let cards = getCards()
        
        if cards.count == 0 {
            return then(nil)
        }
        
        let vids = cards.filter{ $0.kind == .video }
        let pics = cards.filter{ $0.kind == .image }

        if pics.count > 0 {
            return then(pics[0])
        } else if vids.count > 0 {
            return then(vids[0])
        } else {
            return then(cards[0])
        }
    }
    
    
    func getHomeclub( _ then: @escaping(Club?) -> Void ){
        ClubList.shared.getClub(at: self.ogClubID){ club in
            then(club)
        }
    }
}
