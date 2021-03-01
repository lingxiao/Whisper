//
//  PodPlayList.swift
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


//MARK:-item playlist item


struct PodItem {
    var uuid       : String
    var podID     : String
    var uploadedBy: UserID?
    var timeStamp : Int
    var numPlay   : Int
    var order     : Int
    var pod       : PodMedia
}

extension PodItem : Equatable {
    static func == (lhs: PodItem, rhs: PodItem) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}


//MARK:- pod playlist

class PodPlayList : Sink  {
        
    var uid: String
    var name: String = ""
    var timeStamp: Int = 0
    var pods: [PodID:PodItem] = [:]
    
    // playback memory
    private var curr: PodItem?
    private var played: [PodID] = []
    
    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }

    init( at id: String! ){
        self.uid = id
    }
    
    //MARK:- playback API
    
    func play(){
        getCurrentPod()?.pod.play()
    }
        
    func pause(){
        getCurrentPod()?.pod.pause()
    }
    
    func reStart(){
        self.played = []
        self.curr = nil
        let _ = next()
    }
    
    func getCurrentPod() -> PodItem? {
        if let p = self.curr {
            return p
        } else {
            return next()
        }
    }

    func playSelected(pod:PodItem?) -> Bool {

        guard let pod = pod else { return false }
        if Array(self.pods.values).contains(pod) == false { return false }

        if let curr = getCurrentPod() {
            
            if curr == pod {
                play()
                return true
            } else {
                curr.pod.pause()
                self.curr = pod
                play()
                return true
            }
            
        } else {
            
            self.curr = pod
            play()
            return true
        }
        
    }
    
    func next() -> PodItem? {

        let pods = Array(self.pods.values)
        if pods.count == 0 { return nil }

        let ordered = pods
            .filter{ played.contains($0.uuid) == false }
            .sorted{ $0.order < $1.order }

        if ordered.count == 0 {
            self.played = []
            return next()
        } else {
            let top = ordered[0]
            self.curr = top
            self.played.append(top.uuid)
            return top
        }
        
    }
    
    
    func prev() -> PodItem? {
        if self.played.count == 0 {
            return next()
        } else {
            let id = self.played[self.played.count-1]
            let small = self.played.filter{ $0 != id }
            self.played = small
            return self.pods[id]
        }
    }
    
    //MARK:- edit API
    
    func add( pod: PodItem? ){
    }
    
    func remove( pod: PodItem? ){
    }
    
    func suggest(pod: PodItem?){
    }
    
}

//MARK:- data

extension PodPlayList {
    
    func await() {

        PodPlayList.ref(at:self.uuid)?.addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }

            self.name = unsafeCastString(data["name"])
            self.timeStamp = unsafeCastInt(data["timeStamp"])
            
        }
    }
    
    func awaitFull(){
            
        PodPlayList.podColRef(for:self.uuid)?
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    self.decodePodRef(data){ pod in
                        if let pod = pod {
                            self.pods[pod.uuid] = pod
                        }
                    }
                }
        }
    }
    
        
    private func decodePodRef( _ blob : FirestoreData?, _ then: @escaping(PodItem?) -> Void ){
        
        guard let data = blob else { return then(nil) }
        
        guard let uuid = data["uuid"] as? String else { return then(nil) }
        let id = unsafeCastString(data["podID"])

        PodCache.shared.get(at: id){ pod in
    
            guard let pod = pod else { return then(nil) }
            
            // important, actually download the song and make avplayer
            pod.awaitFull()
    
            let pref = PodItem(
                uuid      : uuid,
                podID     : id,
                uploadedBy: unsafeCastString(data["uploadedBy"]),
                timeStamp : unsafeCastInt(data["timeStamp"]),
                numPlay   : unsafeCastInt(data["numPlay"]),
                order     : unsafeCastInt(data["order"]),
                pod       : pod
            )
    
            return then(pref)
        }
    }
}



//MARK:- static-


extension PodPlayList {
    
    static func create( name: String, with pods: [PodItem] ){
    }
    
    static func == (lhs: PodPlayList, rhs: PodPlayList) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    
    static func colRef() -> CollectionReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        return AppDelegate.shared.fireRef?
            .collection("pod_playlist")
    }

    
    static func ref( at uuid: String? ) -> DocumentReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let id = uuid else { return nil }
        if id == "" { return nil }
        let ref = AppDelegate.shared.fireRef?.collection("pod_playlist").document( id )
        return ref
    }
    
    
    static func podColRef(for pid: String? ) -> CollectionReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let pid = pid else { return nil }
        if pid == "" { return nil }
        return AppDelegate.shared.fireRef?
            .collection("pod_playlist")
            .document(pid)
            .collection("pods")
    }
    
    static func podRecRef( for pid: String?) -> CollectionReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        guard let pid = pid else { return nil }
        if pid == "" { return nil }
        return AppDelegate.shared.fireRef?
            .collection("pod_playlist")
            .document(pid)
            .collection("suggested")
    }


}
