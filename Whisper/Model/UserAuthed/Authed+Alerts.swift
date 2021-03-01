//
//  Authed+Alerts.swift
//  byte
//
//  Created by Xiao Ling on 10/26/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation




extension UserAuthed {
    
    // @use: fetch alerts
    func fetchAlerts() -> [AlertBlob] {
        let sorted = Array(alerts.values).sorted{ $0.timeStamp > $1.timeStamp }
        return sorted
    }
    
    func fetchUnseenAlerts() -> [AlertBlob] {
        return fetchAlerts().filter{ $0.seen == false }
    }
    
    func didSeeAlerts(){
        for alert in fetchAlerts() {
            if alert.seen == false {
                UserAuthed.alertCol()?.document(alert.ID).updateData(["seen": true ]){ _ in return }
            }
        }
    }

    // @use: fetch alerts from last 30 days
    func awaitAlerts(){
            
        if self.uuid == "" { return }        
        
        UserAuthed.alertCol()?
            .whereField("target", isEqualTo: self.uuid)
            .order(by: "timeStamp", descending: true)
            .limit(to: 500)
            .addSnapshotListener { querySnapshot, error in
                
                guard let docs = querySnapshot?.documents else { return }
                
                for doc in docs {
                    
                    guard let data = doc.data() as? FirestoreData else {  continue }
                        
                    decodeAlert(data){ blob in
                        
                        guard let blob = blob else { return }
                        if blob.kind != .follow {
                            if self.alerts[blob.ID] == nil {
                                self.alerts[blob.ID] = blob
                                if blob.seen == false {
                                    postFreshAlerts()
                                }
                            }
                        }
                    }
                }
            }
    }
}


