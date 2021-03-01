//
//  FlashCardCache.swift
//  byte
//
//  Created by Xiao Ling on 1/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine


//MARK:- flashcard cache


class FlashCardCache : Sink {
    
    static let shared = FlashCardCache()
    var cards: [CardID:FlashCard] = [:]
    var decks: [DeckID:FlashCardDeck] = [:]
    
    func await(){
        AppDelegate.shared.fireRef?.collection("flash_card_deck")
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["ID"] as? String else { return }
                    if let _ = self.decks[id] {
                        continue
                    } else {
                        let deck = FlashCardDeck(at: id)
                        deck.await()
                        self.decks[id] = deck
                    }
                }
            }
    }

    func awaitPartial(){
        for (_,deck) in self.decks {
            deck.awaitPartial( from: nil )
        }
    }

    //MARK: - API Read
    
    func get( at cid : CardID?, _ then: @escaping(FlashCard?) -> Void){
        
        guard let id = cid else { return then(nil) }
        if id == "" { return then(nil) }
        
        if let card = self.cards[id] {
            return then(card)
        } else {
            let card = FlashCard(at: id)
            card.await()
            self.cards[id] = card
            return then(card)
        }
    }
    
    func checkOutOfAllDeck( from club: Club? ){
        for (_,deck) in self.decks {
            deck.checkout(from: club)
        }
    }
    
}
