//
//  FlashCardDeck+Write.swift
//  byte
//
//  Created by Xiao Ling on 1/9/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

extension FlashCardDeck {
    
    //MARK:- API create cards

    // add word into deck
    func push( front word: String, back defn: String, kind: FlashCardKind = .text ){
        awaitAllDeckCards()
        FlashCard.createText(front: word, back: defn, deckID: self.uuid)
    }
    
    func pushImage( image: UIImage? ){
        awaitAllDeckCards()
        FlashCard.createImage(with: image, at: self.uuid)
    }
    
    func pushVideo( url: URL? ){
        awaitAllDeckCards()
        FlashCard.createVideo(with: url, at: self.uuid)
    }
    
    func pop( _ card: FlashCard? ){
        guard let card = card else { return }
        FlashCard.delete(this: card)
    }
    
    //MARK:- permission
    
    func setPerm( to perm: CardDeckPrivacy?, club: Club? = nil ){

        guard let perm = perm else { return }

        let str = fromCardDeckPrivacy(perm)
        let only : [CardDeckPrivacy]  = [.groupView_groupEdit,.groupView_creatorEdit,.closed]

        var res : FirestoreData = ["perm": str]

        if only.contains(perm) {
            if let club = club {
                res = ["perm": str, "clubID": club.uuid ]
            }
        }

        FlashCardDeck.rootRef(for: self.uuid)?.updateData(res){e in return }
    }

    private func addEditPriv( to user: User? ){
        guard let user = user else { return }
        FlashCardDeck.permRef(for: self.uuid, at: user.uuid)?.setData(["userID": user.uuid, "timeStamp": now()]){ e in return }
    }
    
    private func removeEditPriv( for user: User? ){
        guard let user = user else { return }
        FlashCardDeck.permRef(for: self.uuid, at: user.uuid)?.delete()
    }
    
    //MARK:- navigate cards
    
    func setNext( from club: Club? ){
        
        awaitAllDeckCards()

        var sorted = self.getCards()
        if sorted.count == 0 { return }

        sorted.sort{ $0.timeStamp < $1.timeStamp }
        let sm = sorted.filter{ undo.contains($0.uuid) == false }
        let mid = UserAuthed.shared.uuid
        let cid = club?.uuid ?? ""

        if sm.count > 0 {

            let head = sm[0]
            FlashCardDeck.shuffleRef(for: self.uuid, at: club?.uuid )?.setData( ["ID": head.uuid, "userID": mid, "clubID": cid ] ){e in return }
            
            var ids = [head.uuid]
            let tail = self.undo.filter{ $0 != head.uuid }
            ids.append(contentsOf: tail)
            let short_ids = Array(ids.prefix(20))
            FlashCardDeck.undoRef(for: self.uuid, at: club?.uuid )?.setData( ["IDs": short_ids, "clubID": club?.uuid ?? "" ] ) { e in return }

        } else {
            
            let head = sorted[0]
            FlashCardDeck.shuffleRef(for: self.uuid, at: club?.uuid )?.setData( ["ID": head.uuid, "userID": mid, "clubID": cid ] ){e in return }
            FlashCardDeck.undoRef(for: self.uuid, at: club?.uuid )?.setData( ["IDs": [head.uuid], "clubID": club?.uuid ?? "" ] ) { e in return }
        }
    }
    
    func setPrev( from club: Club? ){

        awaitAllDeckCards()

        let cid = club?.uuid ?? ""
        let sm = undo.filter{ $0 != self.currentCardID }
        if sm.count == 0 { return }
        let head = sm[0]
        let tail = sm.filter{ $0 != head }
        FlashCardDeck.shuffleRef(for: self.uuid, at: club?.uuid )?.setData( ["ID": head, "userID": UserAuthed.shared.uuid, "clubID": cid ] ){e in return }
        FlashCardDeck.undoRef(for: self.uuid, at: club?.uuid )?.setData( ["IDs": tail, "clubID": club?.uuid ?? "" ] ) { e in return }
    }
    
    func shuffleNext( from club: Club? ){

        awaitAllDeckCards()

        if getCards().count > 0 {
            goSetNext(iter:0, club: club)
        }
    }    

    private func goSetNext( iter: Int, club: Club? ){

        var cards = self.getCards()
        cards.shuffle()
        let top = cards[0]
        let cid = club?.uuid ?? ""

        let mid = UserAuthed.shared.uuid
        
        if top.uuid == self.currentCardID {
            cards.shuffle()
            let top2 = cards[0]
            if iter > 10 {
                FlashCardDeck.shuffleRef(for: self.uuid, at: club?.uuid )?.setData( ["ID": top2.uuid, "userID": mid, "clubID": cid ] ){e in return }
                var ids = [top2.uuid]
                let tail = self.undo.filter{ $0 != top2.uuid }
                ids.append(contentsOf: tail)
                let short_ids = Array(ids.prefix(20))
                FlashCardDeck.undoRef(for: self.uuid, at: club?.uuid )?.setData( ["IDs": short_ids, "clubID": club?.uuid ?? "" ] ) { e in return }
            } else {
                goSetNext(iter: iter+1, club: club )
            }
        } else {

            FlashCardDeck.shuffleRef(for: self.uuid, at: club?.uuid )?.setData( ["ID": top.uuid, "userID": mid, "clubID": cid ] ){e in return }
            var ids = [top.uuid]
            let tail = self.undo.filter{ $0 != top.uuid }
            ids.append(contentsOf: tail)
            let short_ids = Array(ids.prefix(20))
            FlashCardDeck.undoRef(for: self.uuid, at: club?.uuid )?.setData( ["IDs": short_ids, "clubID": club?.uuid ?? "" ] ) { e in return }
        }
    }
       
    //MARK:- checkin- checkout
    
    // check into club
    func checkin( from club: Club? ){

        guard let club = club else { return }
        
        // cache client
        let uuid = UUID().uuidString
        self.checkin_buffer[club.uuid] = (uuid,now())
        
        // write server
        let res : FirestoreData = [ "ID": uuid, "deckID": self.uuid, "clubID": club.uuid, "userID": UserAuthed.shared.uuid, "in": now(), "out": now()]
        FlashCardDeck.checkinRef(at: uuid)?.setData( res ){ e in return }
        
        // set alert
        if self.createdBy != UserAuthed.shared.uuid {
            setAlert(for: UserAuthed.shared.uuid, kind: .seeingDeck, meta: club.uuid)
        }
        
        // increment counter
        let num = self.numViews + 1
        FlashCardDeck.statRef( for: self.uuid )?.updateData(["numViews" : num ]){ e in return }
        
    }

    // check out of club
    func checkout( from club: Club? ){

        guard let club = club else { return }

        if let (uuid,t) = self.checkin_buffer[club.uuid] {
            let res : FirestoreData = [ "ID": uuid, "deckID": self.uuid, "clubID": club.uuid, "userID": UserAuthed.shared.uuid, "in": t, "out": now()]
            FlashCardDeck.checkinRef(at: uuid)?.setData( res ){ e in return }
            self.checkin_buffer[club.uuid] = nil
        }
    }
}
