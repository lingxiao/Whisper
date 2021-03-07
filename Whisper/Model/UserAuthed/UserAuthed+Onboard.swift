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
    
    // @use: given number, sync with org
    func syncWithOrg( at code: String?, _ then: @escaping(OrgModel?) -> Void ){
        
        guard let code = code else { return then(nil) }
        
        OrgModel.query(at: code){ org in
            org?.await()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) {
                org?.join()
            }
        }
    } 
    
    // @use: given club number, sync with club
    func syncWithNumber( at code: String?, _ then: @escaping(Club?) -> Void ){
        
        guard let code = code else { return then(nil) }
        
        Club.queryClub(at: code){ club in
            
            guard let club = club else {
                return then(nil)
            }
            
            // await all followers
            club.await()
            
            // wait a bit for club to fetch all members
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                club.join(with: .levelB){ return }
                then( club )
            }
        }
    }
    
    
    /* @Use:
        - log the sponsor and follow everyone that the spnsor follows
        - sent push notification to sponsor saying you are about to log in
    */
    func syncWithSponsor( at code: String?, _ then: @escaping(User?) -> Void ){
        
        guard let code = code else { return then(nil) }
        
        Club.queryClub(at: code){ club in
                
            guard let club = club else {
                return then(nil)
            }
            
            // await all followers
            club.await()
            
            // wait a bit for club to sync and fetch all followers
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0 ) { [weak self] in
                
                guard let self = self else { return then(nil) }
                
                // join sponsor's club and reference
                club.join( with: .levelB ){ return }
                self.sponsor_club = club.uuid
                
                // follow sponsor
                UserList.shared.pull( for: club.creatorID){ (_,_,sponsor) in
                    self.linkToSponsor(at: sponsor, code: code, clubID: club.uuid){ _ in return }
                    then(sponsor)
                }
            }
        }
    }

    private func linkToSponsor( at sponsor: User?, code: String, clubID: String, _ then: @escaping(User?) -> Void ){

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
            "new_account" : false,
            "sponsor_club": clubID
        ]

        UserAuthed.sponsorRef(for: self.uuid)?.updateData( update ){ e in return }

        then(sponsor)
    }
    
}
