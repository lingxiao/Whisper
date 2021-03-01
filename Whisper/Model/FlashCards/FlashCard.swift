//
//  FlashCard.swift
//  byte
//
//  Created by Xiao Ling on 1/1/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine

//MARK:- flashcard domain

enum FlashCardKind {
    case text
    case video
    case audio
    case image
}

func toCardKind( _ str: String ) -> FlashCardKind {
    switch str {
    case "text":
        return .text
    case "video":
        return .video
    case "audio":
        return .audio
    case "image":
        return .image
    default:
        return .text
    }
}

func fromCardKind( _ d : FlashCardKind ) -> String {
    switch d {
    case .text:
        return "text"
    case .video:
        return "video"
    case .audio:
        return "audio"
    case .image:
        return "image"
    }
}


//MARK:- flash card

class FlashCard : Sink {

    var uid: UniqueID
    
    var front: String = ""
    var back : String = ""
    var kind : FlashCardKind = .text
    
    var timeStamp: Int = now()
    var numRight: Int  = 0
    var numWrong: Int  = 0
    var numFlag : Int  = 0
    var createdBy: UserID = ""
    var creator : User?
    var deckID: String = ""
    var ORDER: Int = 0
    
    var mediaURL: URL?
    var mediaURLStr: String = ""
    var mediaStoreUploadURL = ""
    var is_original_media: Bool = true
    
    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }
    
    init( at id: String! ){
        self.uid = id
    }
    
    
    func await(){
        if self.uuid == "" { return }
        FlashCard.rootRef(for:self.uuid)?.addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.front     = unsafeCastString(data["front"])
            self.back      = unsafeCastString(data["back"])
            self.timeStamp = unsafeCastInt(data["timeStamp"])
            self.numRight  = unsafeCastIntToZero(data["numRight"])
            self.numWrong  = unsafeCastIntToZero(data["numWrong"])
            self.numFlag   = unsafeCastIntToZero(data["numFlag"])
            self.kind      = toCardKind( unsafeCastString(data["kind"]) )
            self.deckID    = unsafeCastString(data["deckID"])
            self.createdBy = unsafeCastString(data["createdBy"])
            self.ORDER     = unsafeCastIntToZero(data["ORDER"])
            
            UserList.shared.pull(for: self.createdBy){(_,_,user) in
                self.creator = user
            }
            
            self.is_original_media   = unsafeCastBool(data["is_original_media"])
            self.mediaStoreUploadURL = unsafeCastString(data["mediaStoreUploadURL"])

            let url_str = unsafeCastString(data["mediaStoreURL_lg"])

            if url_str != "" {
                let prevURL = self.mediaURL
                self.mediaURLStr = url_str
                self.mediaURL = URL(string: url_str)
                if prevURL != self.mediaURL && self.kind == .image {
                    if let _url = self.mediaURL {
                        let source = ImageLoader.shared.loadImage(from: _url)
                        let _ =  source.sink { _ in return}
                    }
                }
            }
            
        }
    }
    
    func awaitMedia( _ then: @escaping(URL?) -> Void ){
        if self.uuid == "" { return }
        switch self.kind {
        case .video:
            if self.mediaURLStr != "" {
                VideoCache.shared.getFileWith(stringUrl: mediaURLStr){ res in
                    switch res {
                    case.failure( _ ):
                        then(nil)
                    case .success(let url):
                        then(url)
                    }
                }
            }
        default:
            then(nil)
        }
    }
    
    //MARK:- API
    
    func gotRight(){
        FlashCard.rootRef(for: self.uuid)?.updateData(["numRight":numRight+1]){e in return }
    }
    
    func gotWrong(){
        FlashCard.rootRef(for: self.uuid)?.updateData(["numWrong":numWrong+1]){e in return }
    }
    
    func flag(){
        FlashCard.rootRef(for: self.uuid)?.updateData(["numFlag":numFlag+1]){e in return }
    }
    
    func isMine() -> Bool {
        return UserAuthed.shared.uuid == self.createdBy
    }
}

//MARK:- read

extension FlashCard : Renderable {

    func get_H1() -> String {
        return self.front
    }
    
    func get_H2() -> String {
        return self.back
    }
    
    func fetchThumbURL() -> URL? {
        return self.mediaURL
    }
    
    func match(query: String?) -> Bool {
        return false
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    
}

    
 //MARK:- static

extension FlashCard {

    
    static func == (lhs: FlashCard, rhs: FlashCard) -> Bool {
        lhs.front == rhs.front
    }
    
        
    static func rootRef( for id : CardID? ) -> DocumentReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("flash_cards").document( id )
    }
    
    static func deleteRef( for id: String ) -> DocumentReference? {
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("firebase_server_task").document(id)
    }
    
    static func delete( this card: FlashCard? ){

        guard let card = card else { return }
        
        let url = card.mediaStoreUploadURL
        let do_rmv = card.is_original_media
        
        if do_rmv && url != "" {
            FlashCard.deleteRef(for: UUID().uuidString )?.setData( ["url": url] ){ e in return }
        }

        FlashCard.rootRef(for: card.uuid)?.delete()
        FlashCardCache.shared.cards[card.uuid] = nil

    }
        
    // create a card with text
    static func createText( front: String?, back: String?, deckID: String ){
        
        guard let front = front else { return }
        guard let back = back else { return }
        
        if front == "" { return }
        let id = UUID().uuidString
        
        var stub = mkCardStub(with: id)
        stub["front"]  = front
        stub["back"]   = back
        stub["deckID"] = deckID
        stub["kind"]   = fromCardKind(.text)
        
        FlashCard.rootRef(for: id)?.setData( stub ){ e in return }

    }
    
    // create a card with text
    static func createImage( with image: UIImage?, at deckID: String ){
        
        guard let img = image else { return }
        guard AppDelegate.shared.canStore() else { return }

        let uuid  = UUID().uuidString
        let small = img.jpegData(compressionQuality: 0.25)
        let path  = "card_media/\(uuid).jpg"

        UserAuthed.uploadImage( to: path, with: small ){ (succ, url) in
            
            if url == "" { return }
            var stub = mkCardStub(with: uuid)
            stub["deckID"] = deckID
            stub["kind"] = fromCardKind(.image)
            stub["mediaStoreURL_lg"] = url
            stub["mediaStoreUploadURL"] = path
            FlashCard.rootRef(for: uuid)?.setData( stub ){ e in return }
        }

    }
    
    static func createVideo( with url: URL?, at deckID: String ){
        
        let uuid = UUID().uuidString
        
        UserAuthed.uploadVideo( to: uuid, with: url){ (url,path) in
            
            var stub = mkCardStub(with: uuid)
            stub["deckID"] = deckID
            stub["kind"] = fromCardKind(.video)
            stub["mediaStoreURL_lg"] = url
            stub["mediaStoreUploadURL"] = path
            FlashCard.rootRef(for: uuid)?.setData( stub ){ e in return }

        }

    }

}



//MARK:- utils


private func mkCardStub( with id: String ) -> FirestoreData {
    
    let res : FirestoreData = [
     "ID"       : id,
     "timeStamp": now(),

     "front"    : "",
     "back"     : "",
     "kind"     : fromCardKind(.text),

     "mediaStoreURL_sm": "",
     "mediaStoreURL_lg": "",
     "mediaStoreUploadURL": "",
     "is_original_media": true,

     "numRight" : 0,
     "numWrong" : 0,
     "numFlag"  : 0,
     "createdBy": UserAuthed.shared.uuid,
     "deckID"   : "",
     "ORDER"    : 0
    ]
    
    return res
}

func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.data(using: .utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
            return json
        } catch {
            print("Something went wrong")
        }
    }
    return nil
}




/*
 
 func fillSAT(){
              
     let str = "https://raw.githubusercontent.com/lrojas94/SAT-Words/master/MajorTests%20Wordlist/majortests_words.json"
     let deckid = "5C6999DC-670B-4DD4-8A81-D0887F895215"

     guard let url = URL(string:str) else { return }
     guard let deck = FlashCardCache.shared.decks[deckid] else { return }
  
     URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
           if let jsonString = String(data: data, encoding: .utf8) {
              let xs = jsonString.split(separator: "}")
              for x in xs {
                  var y = x
                  y.remove(at: y.startIndex)
                  let z = String(y)
                  let str = "\(z)}"
                  if let dict = convertStringToDictionary(text: str){
                      if let def = dict["definition"] as? String {
                          if let word = dict["word"] as? String {
                              print( word, def )
                              DispatchQueue.main.async {
                                 deck.push(front: word, back: def, kind: .text)
                              }
                          }
                      }
                      print("---------")
                  } else {
                      print("xxx")
                  }
              }
           }
         }
     }.resume()
 }

*/
