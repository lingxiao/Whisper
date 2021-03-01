//
//  PodMedia.swift
//  byte
//
//  Created by Xiao Ling on 12/28/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine
import AVFoundation



//MARK:- PodCache

/**
 @use: fetch live events for news feed
       static functions for initiating calls
*/
class PodCache : Sink {
    
    static let shared = PodCache()
    var pods: [PodID:PodMedia] = [:]
    
    func await(){
        return
    }
    
    func get( at pid : PodID?, forceEval: Bool = false, _ then: @escaping(PodMedia?) -> Void){
        
        guard let id = pid else { return then(nil) }
        if id == "" { return then(nil) }
        
        if let pod = self.pods[id] {
            return then(pod)
        } else {
            let pod = PodMedia(at: id)
            pod.await()
            if forceEval { pod.awaitFull() }
            self.pods[id] = pod
            return then(pod)
        }
    }
}


//MARK:- one pod media item

class PodMedia : Sink, Renderable {
    
    var uid : PodID
    
    var artistID : UserID = ""
    var artistName: String = ""
    var artist   : User? = nil
    
    var trackName: String = ""
    var url      : String = ""
    var imageURL : String = ""
    var player: AVPlayer? = nil

    var timeStamp: Int = 0
    var uploaded : Int = 0
    var totalPlays: Int = 0
    
    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }
        
    init( at id: String! ){
        self.uid = id
    }
    

    //MARK:- static
    
    static func podRef( for uid: String? ) -> DocumentReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("pods").document(uid)
    }
    
    static func == (lhs: PodMedia, rhs: PodMedia) -> Bool {
        return lhs.uuid == rhs.uuid
    }


    //MARK:- API

    func await() {
        PodMedia.podRef(for:self.uuid)?.getDocument { documentSnapshot, error in
            guard let doc = documentSnapshot else { return }
            guard let data = doc.data() else { return }
            self.decodePodRoot(data)
        }
    }
    
    func awaitFull(){
        PodMedia.podRef(for:self.uuid)?.getDocument { documentSnapshot, error in
            guard let doc = documentSnapshot else { return }
            guard let data = doc.data() else { return }
            self.decodePodMedia(data)
        }
    }
    
    func play(){
        player?.play()
    }
    
    func pause(){
        player?.pause()
    }
    
    func rewind(){
    }

    func isPlaying() -> Bool {
        guard let player = player else { return false }
        return player.timeControlStatus == .playing
    }
    
    
    //MARK:- renderable
    
    func get_H1() -> String {
        return self.trackName
    }
    
    func get_H2() -> String {
        return self.artistName
    }
    
    func fetchThumbURL() -> URL? {
        return self.imageURL != "" ? URL(string: self.imageURL) : nil
    }
    
    func match( query: String? ) -> Bool {
        guard let xs = query else { return false }
        let patterns = generateSearchQueriesForUser(name: xs, email: "")
        return patterns.contains(self.trackName)
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    

    //MARK:- private db fn
    
    private func decodePodRoot( _ blob: FirestoreData? ){
        
        guard let data = blob else { return }
        
        guard let uuid = data["uuid"] as? String else { return }
        if uuid == "" { return }
        
        let userid = unsafeCastString(data["artistID"])
        let imgURL = unsafeCastString(data["imageURL"])

        self.artistID = userid
        self.artistName = unsafeCastString(data["artistName"])
        self.trackName  = unsafeCastString(data["trackName"])
        self.imageURL   = imgURL
        
        self.timeStamp   = unsafeCastInt(data["timeStamp"])
        self.uploaded    = unsafeCastInt(data["uploaded"])
        self.totalPlays  = unsafeCastInt(data["totalPlays"])

        // cache track image url
        if imgURL != "" {
            if let imurl = URL(string:imgURL) {
                let source = ImageLoader.shared.loadImage(from: imurl)
                let _ = source.sink { _ in return }
            }
        }
    }

    /*
     @use: decode pod and create player
    */
    private func decodePodMedia( _ blob : FirestoreData? ){
        
        guard let data = blob else { return }
        
        guard let uuid = data["uuid"] as? String else { return }
        if uuid == "" { return }

        let surl = unsafeCastString(data["url"])
        if surl == "" { return }
        
        guard let storageRef = AppDelegate.shared.storeRef?.reference().child(surl) else { return }
        
        // Fetch the download URL
        storageRef.downloadURL { url, error in
            guard let url = url else { return }
            let player  = AVPlayer(playerItem: AVPlayerItem(url: url))
            self.player = player
        }

        // download user
        let userid = unsafeCastString(data["artistID"])
        self.artistID = userid
        UserList.shared.pull(for: userid){ (_,_,user) in
            self.artist = user
        }
    }

}
