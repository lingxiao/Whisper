//
//  FlashCardDeck.swift
//  byte
//
//  Created by Xiao Ling on 1/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import UIKit


//MARK:- constants


enum CardDeckPrivacy {
    case openView_openEdit
    case openView_groupEdit
    case openView_creatorEdit
    case groupView_groupEdit
    case groupView_creatorEdit
    case closed
}

let deckPrivacyOpts: [CardDeckPrivacy] = [
      .openView_openEdit
    , .openView_groupEdit
    , .openView_creatorEdit
    , .groupView_groupEdit
    , .groupView_creatorEdit
    , .closed
]


func fromCardDeckPrivacy( _ perm: CardDeckPrivacy ) -> String {
    switch perm {
    case .openView_openEdit:
        return "openView_openEdit"
    case .openView_groupEdit:
        return "openView_groupEdit"
    case .openView_creatorEdit:
        return "openView_creatorEdit"
    case .groupView_groupEdit:
        return "groupView_groupEdit"
    case .groupView_creatorEdit:
        return "groupView_creatorEdit"
    case .closed:
        return "closed"
    }
}

func toCardDeckPrivacy( _ str: String ) -> CardDeckPrivacy {
    switch str {
    case "openView_openEdit":
        return .openView_openEdit
    case "openView_groupEdit":
        return .openView_groupEdit
    case "openView_creatorEdit":
        return .openView_creatorEdit
    case "groupView_groupEdit":
        return .groupView_groupEdit
    case "groupView_creatorEdit":
        return .groupView_creatorEdit
    default:
        return .closed
    }
}



protocol FlashCardDeckDelegate {
    func didLoadNewCard( at card: FlashCard ) -> Void
    func onSyncedNextCard( at card : FlashCard ) -> Void
}




//MARK:- class

class FlashCardDeck : Sink {
    
    var uid : DeckID

    var name: String   = ""
    var tags: [String] = []
    var createdBy: UserID = ""
    var timeStamp: Int = ThePast()
    var creator : User?
    var color: UIColor = UIColor.clear
    var imgURL: URL?
    var imgStoreURL: String = ""

    var currentCardID: CardID = ""
    var pickedBy: User?
    var homeClubID: String = ""
    var ogClubID: String = ""
    var numViews: Int = 0

    // perm
    var perm: CardDeckPrivacy = .closed
    var priv_users : [UserID] = []
    
    // users who tagged this deck
    var tagged_users: [User] = []
    var numTags: Int = 0
    
    // browsing history
    var checkin_history: [String:DeckAudience] = [:]
    var checkin_buffer: [ClubID:(String,Int)] = [:]
    var undo: [CardID] = []
    
    // sync parameter
    private var hasSyncedCards: Bool = false
    private var hasSyncedTaggers: Bool = false
    private var hasSyncedHistory: Bool = false

    var delegate: FlashCardDeckDelegate?
    
    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }
    
    init( at id: String! ){
        self.uid = id
    }
    
    func await(){

        FlashCardDeck.rootRef(for:self.uuid)?.addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }

            self.timeStamp = unsafeCastInt(data["timeStamp"])
            self.createdBy = unsafeCastString(data["createdBy"])
            self.name = unsafeCastString(data["name"])
            self.color = fromColorDbCode( unsafeCastInt(data["color"])  )
            self.perm = toCardDeckPrivacy(unsafeCastString(data["perm"]))
            self.homeClubID = unsafeCastString(data["clubID"])
            self.ogClubID = unsafeCastString(data["clubID_OG"])

            if let tags = data["tags"] as? [String]{
                self.tags = tags
            }

            UserList.shared.pull(for: self.createdBy){(_,_,user) in
                self.creator = user
            }
            
            // get image and cache
            let url = unsafeCastString(data["imgURL"])
            if url == "" { return }
            self.imgURL = URL(string: url)
            if let URL = self.imgURL {
                let source = ImageLoader.shared.loadImage(from: URL)
                let _ = source.sink { [unowned self] image in return }
            }
            self.imgStoreURL = unsafeCastString(data["imgStoreURL"])
        }
        
        FlashCardDeck.statRef(for:self.uuid)?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.numViews = unsafeCastIntToZero(data["numViews"])
        }
            
        // await card of each kind
        awaitFlashCards(upto: 1, only: .text , once: true)
        awaitFlashCards(upto: 1, only: .video, once: true)
        awaitFlashCards(upto: 1, only: .image, once: true)
    }
    
    func awaitPartial( from club: Club? ){
        await_undo( club )
        awaitShuffle( club )
        awaitTaggers()
        await_checkin_history()
    }
    
    func awaitAllDeckCards(){
        if self.hasSyncedCards == false {
            self.hasSyncedCards = true
            awaitFlashCards(upto: -1, only: nil, once: false)
        }
    }
    
    private func awaitFlashCards( upto n : Int, only kind: FlashCardKind?, once: Bool ){
        
        var ref = AppDelegate.shared
            .fireRef?
            .collection("flash_cards")
            .whereField("deckID", isEqualTo: self.uuid)
        
        if let kind = kind {
            ref = ref?.whereField("kind", isEqualTo: fromCardKind(kind))
        }
        
        if n > 0 {
            ref = ref?.order(by: "timeStamp", descending: true).limit(to: n)
        }
        
        func parse( _ querySnapshot: QuerySnapshot? ){
            guard let docs = querySnapshot?.documents else { return }
            for doc in docs {
                guard let data = doc.data() as? FirestoreData else { continue }
                guard let id = data["ID"] as? String else { return }
                FlashCardCache.shared.get(at: id){ card in
                    if let card = card {
                        self.delegate?.didLoadNewCard(at: card)
                    }
                }
            }
        }
        
        if once {
            ref?.getDocuments() { (querySnapshot, err) in
                parse(querySnapshot)
            }
        } else {
            ref?.addSnapshotListener { querySnapshot, error in
                parse(querySnapshot)
            }
        }
    }
    
    
    private func awaitShuffle( _ club: Club? ){
        FlashCardDeck.shuffleRef(for: self.uuid, at: club?.uuid )?
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else { return }
                guard let data = document.data() as FirestoreData? else { return }
                let pid = self.currentCardID
                self.currentCardID = unsafeCastString(data["ID"])
                if pid != self.currentCardID {
                    FlashCardCache.shared.get(at: self.currentCardID){ card in
                        guard let card = card else { return }
                        let uid = unsafeCastString(data["userID"])
                        UserList.shared.pull(for: uid){(_,_,user) in
                            self.pickedBy = user
                            self.delegate?.onSyncedNextCard(at: card)
                        }
                    }
                }
            }
    }
    
    // await those who have tagged this
    private func awaitTaggers(){
        
        if hasSyncedTaggers { return }
        self.hasSyncedTaggers = true

        FlashCardDeck.rootRef(for: self.uuid)?.collection("tagged_by")
            .addSnapshotListener { querySnapshot, error in

                guard let docs = querySnapshot?.documents else { return }

                for doc in docs {

                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id  = data["userID"] as? String else { return }
                    
                    UserList.shared.pull(for: id){(_,_,user) in
                        guard let user = user else { return }
                        if self.tagged_users.contains(user) == false {
                            self.tagged_users.append(user)
                        }
                    }

                }
            }
    }
    
    private func await_checkin_history(){
        
        if self.hasSyncedHistory { return }
        self.hasSyncedHistory = true
        
        FlashCardDeck.checkinColRef()?
            .whereField("deckID", isEqualTo: self.uuid)
            .addSnapshotListener { querySnapshot, error in

                guard let docs = querySnapshot?.documents else { return }

                for doc in docs {
                    
                    guard let data = doc.data() as? FirestoreData else { continue }

                    decodeDeckAudience(data){ aud in

                        guard let aud = aud else { return }

                        let hist = Array(self.checkin_history.values)
                            .filter{ $0.user.uuid == aud.user.uuid }
                            .filter{ deckAudienceIsHere(for:$0) }
                            .map{ $0.user }
                        
                        if deckAudienceIsHere(for:aud) {
                            if hist.contains(aud.user) == false {
                                self.checkin_history[aud.uuid] = aud
                            }
                        } else {
                            self.checkin_history[aud.uuid] = aud
                        }
                    }
                }
            }
    }

    
    private func await_undo( _ club: Club? ){
        FlashCardDeck.undoRef(for: self.uuid, at: club?.uuid )?
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else { return }
                guard let data = document.data() as FirestoreData? else { return }
                if let ids = data["IDs"] as? [String] {
                    self.undo = ids
                }
            }
    }
    

    //MARK:- pretty print
    
    func pp_num_tagged() -> String {
        let taggers = self.tagged_users
        var lstr = ""
        switch taggers.count {
        case 0 :
            lstr = "Be the first to tag this collection."
        case 1:
            lstr = "Tagged by \(taggers[0].get_H1())"
        case 2:
            lstr = "Tagged by \(taggers[0].get_H1()) and \(taggers[1].get_H1())"
        case 3:
            lstr = "Tagged by \(taggers[0].get_H1()), \(taggers[1].get_H1()), and 1 other"
        default:
            let n = taggers.count - 2
            lstr = "Tagged by \(taggers[0].get_H1()), \(taggers[1].get_H1()), and \(n) others"
        }
        self.numTags = taggers.count
        return lstr
    }
    
    //MARK:- static
    
    static func rootRef( for id : String? ) -> DocumentReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("flash_card_deck").document( id )
    }
    
    static func scheduleDeleteRef( for id: String? )-> DocumentReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("flash_card_deck_schedule_delete").document( id )
    }

    static func permRef( for id : String?, at uuid: UserID? ) -> DocumentReference? {
        guard let uuid = uuid else { return nil}
        if uuid == "" { return nil }
        return FlashCardDeck.rootRef(for: id)?.collection("can_edit").document(uuid)
    }
    
    static func statRef( for id : String? ) -> DocumentReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?
            .collection("flash_card_deck")
            .document( id )
            .collection("stats")
            .document(id)
    }

    static func shuffleRef( for id : String?, at clubID: String? ) -> DocumentReference? {

        guard let id = id else { return nil }
        guard let clubid = clubID else { return nil }
        if id == "" { return nil }
        if clubid == "" { return nil }
        
         return AppDelegate.shared.fireRef?
             .collection("flash_card_deck")
             .document( id )
             .collection("shuffle")
             .document(clubid)
    }
    
    
    static func undoRef( for id : String?, at clubID: String? ) -> DocumentReference? {

        guard let id = id else { return nil }
        guard let clubid = clubID else { return nil }
        if id == "" { return nil }
        if clubid == "" { return nil }

        return AppDelegate.shared.fireRef?
             .collection("flash_card_deck")
             .document( id )
             .collection("undo")
             .document(clubid)
    }
    
    static func tagRef( for deckID: String?, at groupID: String? ) -> DocumentReference? {
        guard let did = deckID else { return nil }
        guard let gid = groupID else { return nil}
        if did == "" || gid == "" { return nil }
        return FlashCardDeck.rootRef(for: did)?
            .collection("tagged_by")
            .document( gid )
    }
    
    static func checkinColRef() -> CollectionReference? {
        return AppDelegate.shared.fireRef?.collection("flash_card_deck_checkin")
    }
    
    static func checkinRef( at ID: String? ) -> DocumentReference? {
        guard let id = ID else { return nil}
        if id == "" { return nil }
        return FlashCardDeck.checkinColRef()?.document( id )
    }

    
    // @use create deck
    static func create( name: String, tag: [String], from club: Club? = nil, color: UIColor = Color.blue1, image: UIImage?  ) -> DeckID {
        
        let id = UUID().uuidString
        FlashCardDeck.rootRef(for: id)?.setData(
            ["ID"       : id,
             "name"     : name,
             "tags"     : tag,
             "timeStamp": now(),
             "createdBy": UserAuthed.shared.uuid,
             "perm"     : fromCardDeckPrivacy(.openView_groupEdit),
             "clubID"   : club?.uuid ?? "",
             "clubID_OG": club?.uuid ?? "",
             "color"    : toColorDbCode(color),
             "imgURL"   : "",
             "imgURLSlug": "",
             "numTags"  : 0,
            ]){e in return }
        
        // incr stub
        FlashCardDeck.statRef( for: id )?.setData(["numViews" : 1 ]){ e in return }
        
        // tag this deck for this club
        if let club = club {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0 ) {
                if let deck = FlashCardCache.shared.decks[id] {
                    club.tagDeck(at: deck, invite: false)
                }
            }
        }
        
        // upload image
        if let img = image {
            let small  = img.jpegData(compressionQuality: 0.20)
            let path : String = "\(id)/coverImageSmall.jpg"
            UserAuthed.uploadImage( to: path, with: small ){ (succ, url) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0 ) {
                    FlashCardDeck.rootRef(for: id)?.updateData(
                        ["imgURL":url, "imgStoreURL": path]
                    ){ e in return }
                }
            }
        }
        
        return id
    }
    
    
    static func delete( deck: FlashCardDeck? ){
        
        guard let deck = deck else { return }
        
        let imgStoreURL = deck.imgStoreURL
        
        // mark for deletion for server listener
        FlashCardDeck
            .scheduleDeleteRef( for: deck.uuid )?
            .setData( ["ID": deck.uuid] ){ e in return }
        
        // delete stubs from the client
        FlashCardDeck.statRef(for:deck.uuid)?.delete()
        FlashCardDeck.rootRef(for: deck.uuid)?.delete()
        
        // remove client side cache
        FlashCardCache.shared.decks[deck.uuid] = nil
        
        // delete picture
        if imgStoreURL != "" {
            UserAuthed.deleteMedia(at: imgStoreURL)
        }

    }

}
