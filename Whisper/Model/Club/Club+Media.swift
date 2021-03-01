//
//  Club+Media.swift
//  byte
//
//  Created by Xiao Ling on 12/27/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine
import AVFoundation



extension Club {
    
    //MARK:- API
    
    func getNextPlayList() -> PodPlayList? {

        let pls = Array(media.values)
        if pls.count == 0 { return nil }

        let small = pls.filter{ prevPlayList.contains($0.uuid) == false }

        if small.count == 0 {
            self.prevPlayList = []
            return self.getNextPlayList()
        } else {
            let top = small[0]
            self.currentPlayList = top
            self.prevPlayList.append(top.uuid)
            return top
        }
    }
    
    func getCurrentPlayList() -> PodPlayList? {
        if let p = self.currentPlayList {
            return p
        } else {
            return getNextPlayList()
        }
    }
        
    func getCurrentPod() -> PodItem? {
        return getCurrentPlayList()?.getCurrentPod()
    }
    
    func playCurrentPod(){
        self.getCurrentPlayList()?.play()
    }

    func pauseCurrentPod(){
        self.getCurrentPlayList()?.pause()
    }
    
    func getCurrentPodImage() -> URL? {
        if let str = getCurrentPod()?.pod.imageURL {
            return URL(string:str)
        } else {
            return nil
        }
    }
    
    func playSelected(pod: PodItem?){
        guard let pl =  getCurrentPlayList() else { return }
        let _ = pl.playSelected(pod:pod)
    }

    func goToNextPod() -> PodItem? {
        return getCurrentPlayList()?.next()
    }

    func playNextPod( _ then: @escaping() -> Void) {
        self.getCurrentPlayList()?.pause()
        let _ = self.currentPlayList?.next()
        self.getCurrentPlayList()?.play()
        then()
    }
    
    func podIsPlaying() -> Bool {
        guard let pod = getCurrentPlayList()?.getCurrentPod() else { return false }
        return pod.pod.isPlaying()
    }
    
    
    //MARK:- private or internal
        
    // download song metadata ( trackname, artistname, etc ) from remote db
    func awaitPlayListStubs(){
        
        PodPlayList.colRef()?
            .whereField("clubID", isEqualTo: self.uuid)
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return print("else case") }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    let id = unsafeCastString(data["uuid"])
                    let pl = PodPlayList(at: id)
                    pl.await()
                    self.media[pl.uuid] = pl
                }
        }

    }
    
    // download song from remote db
    func awaitFullPlayList(){
        for (_,pl) in self.media {
            pl.awaitFull()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            self?.delegate?.didAddPlayList()
        }
    }

    
}

