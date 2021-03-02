//
//  Club+Cards.swift
//  byte
//
//  Created by Xiao Ling on 1/1/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation



extension Club {
    
    func tagDeck(at deck: FlashCardDeck?, invite: Bool ){

        guard let deck = deck else { return }

        Club.deckRef(for:self.uuid,at:deck.uuid)?.setData(["ID":deck.uuid,"timeStamp":now()]){e in return}
        
        // send invite
        if let user = deck.creator {
            if user.isMe() == false && invite {
                //setAlert(for: user.uuid, kind: .taggedDeckAndInviteToGroup, meta: self.uuid)
            }
        }
        
        // alert tag
        deck.didTag( by: self )
    }
    
    func untagDeck(at deck: FlashCardDeck?){
        guard let deck = deck else { return }
        Club.deckRef(for:self.uuid,at:deck.uuid)?.delete()
        let sm = self.deckIDs.filter{ $0 != deck.uuid }
        self.deckIDs = sm
        deck.didUntag(by:self)
    }
    
    func getMyDeck() -> [FlashCardDeck] {
        return Array(FlashCardCache.shared.decks.values).filter{ self.deckIDs.contains($0.uuid) }
    }
    
    func taggedThisDeck( at deck: FlashCardDeck? ) -> Bool {
        guard let deck = deck else { return false }
        return getMyDeck().map{ $0.uuid}.contains( deck.uuid )
    }

    func awaitMyFlashCards(){
        Club.rootRef(for: self.uuid)?
            .collection("flash_card_deck")
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? String else { continue }
                    self.deckIDs.append(id)
                }
            }
    }

    
}
