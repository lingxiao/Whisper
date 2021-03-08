//
//  UserAuthed+Onboard.swift
//  byte
//
//  Created by Xiao Ling on 10/29/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth


//MARK:- onboarding

private let AggressiveFollow : Bool = true

extension UserAuthed {

    public func didDragNewsFeed(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["did_drag_news_feed":true])
    }

    
    public func didDragAudioRoom(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["did_drag_audio_room":true])
    }
    
    public func didDragDeck(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["did_drag_deck":true])
    }
    
    public func didSwitchRoom(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["did_switch_rooms":true])        
    }
    
    public func didConsentToEmphemeralClub(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["did_consent_to_emphemeral_club":true])
    }
    
    public func syncedContacts(){
        UserAuthed.onboardWalkThruRef(for: self.uuid)?.updateData(["didSyncContacts":true])
    }
    
    // @use: given number, sync with org, alert org host I have joined
    func syncWithOrg( at code: String?, _ then: @escaping((OrgModel?,Club?)) -> Void ){
        
        guard let code = code else { return then((nil,nil)) }
        
        OrgModel.query(at: code){ org in
            if let org = org {
                org.await()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) {
                    org.join()
                    UserList.shared.pull(for: org.creatorID){ (_,_,sponsor) in
                        self.linkToSponsor(at: sponsor, code: code, orgID: org.uuid){ _ in return }
                    }
                    then( (org, org.getHomeClub()) )
                }
            } else {
                then((nil,nil))
            }
        }
    } 
    

    private func linkToSponsor( at sponsor: User?, code: String, orgID: String, _ then: @escaping(User?) -> Void ){

        guard let sponsor = sponsor else {
            return then(nil)
        }

        self.sponsor = sponsor
        self.sponsor_id = sponsor.uuid

        ClubList.shared.sendPushNotificationToSponsor( to: [sponsor.uuid] )

        self.follow(sponsor)
        let update : FirestoreData = [
            "invite_code" : code,
            "sponsor"     : sponsor.uuid,
            "sponsorOrg"  : orgID,
            "new_account" : false
        ]

        UserAuthed.sponsorRef(for: self.uuid)?.updateData( update ){ e in return }

        then(sponsor)
    }
    
}
