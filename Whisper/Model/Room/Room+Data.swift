//
//  Room+Data.swift
//  byte
//
//  Created by Xiao Ling on 12/6/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


//MARK:- root

extension Room {
    
    func awaitRoot(){
        
        // parse root
        Room.rootRef(for:self.uuid)?.addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }

            let prev_call_st = self.call_state
            let prev_rec = self.isRecording
            
            self.call_state  = toCallState(unsafeCastString(data["state"]))
            self.isRoot = unsafeCastBool(data["isRoot"])
            self.timeStamp = unsafeCastInt(data["timeStamp"])
            self.isRecording = unsafeCastBool(data["isRecording"])
            self.createdBy = unsafeCastString(data["createdBy"])
            
            if prev_call_st != self.call_state {
                
                switch( self.call_state ){
                case .ended:
                    self.delegate?.didExitLive( from: self )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                        guard let self = self else { return }
                        if self.call_state == .ended {
                            postRefreshClubs( at: self.clubID )
                            postRefreshClubPage(at:self.club?.uuid ?? "")
                        }
                    }
                case .liveHostAudio:
                    self.delegate?.didLiveHostAudio()
                    postRefreshClubs( at: self.clubID )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.50 ) { [weak self] in
                        postRefreshClubPage(at:self?.club?.uuid ?? "")
                    }
                default:
                    break;
                }
            }
            
            let prev_room_mode = self.room_mode
            self.room_mode = roomPerm( unsafeCastString(data["permission"]))
                    
            if prev_room_mode != self.room_mode {
                self.delegate?.didChangeRoomPerm( perm: self.room_mode )
            }
            
            if prev_rec != self.isRecording {
                if self.isRecording {
                    self.delegate?.didStartRecord()
                } else {
                    self.delegate?.didEndRecord()
                }
            }
            
            // deleted
            let prev_rmv = self.deleted
            self.deleted = unsafeCastBool(data["deleted"])
            self.deleteDate = unsafeCastInt(data["deleteDate"])
                
            if prev_rmv == false && self.deleted {
                postRoomDidDelete(roomID:self.uuid)
            }            
        }
        
    
    }
}

//MARK:- room audience

extension Room {
    
    // @use: await current event audience
    func awaitAudience(){
        
        Room.audienceCollectionRef(for: self.uuid)?
            .addSnapshotListener { querySnapshot, error in
             
                guard let docs = querySnapshot?.documents else { return }
                
                for doc in docs {

                    guard let data = doc.data() as? FirestoreData else { continue }
                    
                    decodeRoomMember(data){ member in                        
                        guard let member = member else { return }
                        let prev = self.audience[ member.uuid ]
                        self.audience[ member.uuid ] = member
                        self.bubbleEvents(prev: prev, next: member)
                    }
                }
            }
    }
    

    /*
     @use: check delta in user-state, and bubble up changes
     */
    private func bubbleEvents( prev: RoomMember? , next: RoomMember ){
        
        let user = next.user
        
        if let prev = prev {

            // is muted
            if prev.muted != next.muted {
                delegate?.didChangeMute(at: next, to: next.muted)
                if next.muted {
                    postDidMute( userID: user.uuid, roomID: self.uuid )
                    postDidUnSpeaking(userID: user.uuid, roomID: self.uuid)
                } else {
                    postDidUnMute( userID: user.uuid, roomID: self.uuid )
                }
            }
            

            if prev.state == next.state { return }
            
            // bubble did join
            if prev.state == .notHere && next.state != .notHere {

                delegate?.onNewAudience( at: next, didJoin: true )
                postRefreshClubs( at: self.clubID )
                if user.isMe() {
                    postIdidJoinOrLeaveRoom(at: self.club?.uuid ?? "")
                }
 
            } else if prev.state != .notHere && next.state == .notHere {
                
                delegate?.onNewAudience( at: next, didJoin: false )
                postRefreshClubs( at: self.clubID )
                if user.isMe() {
                    postIdidJoinOrLeaveRoom(at: self.club?.uuid ?? "")
                }

            }

            // bubble raise hand
            if prev.state != .raisedHand && next.state == .raisedHand {
                
                delegate?.onRaiseHand( at: next, raised: true )

            } else if prev.state == .raisedHand && next.state != .raisedHand {
                
                delegate?.onRaiseHand( at: next, raised: false )
                
            }

            // bubble speaking
            if prev.state != .speaking && next.state == .speaking {
                
                delegate?.onNewOnStage(at: next, on: true)
                
            } else if prev.state == .speaking && next.state != .speaking && next.state != .podding {
                
                delegate?.onNewOnStage(at: next, on: false)

            }
            
            // bubble podding
            if prev.state != .podding && next.state == .podding {
                
                delegate?.onPodding( at: next, podding: true )
                videoDelegate?.didEnterPodding()
                
            } else if prev.state == .podding && next.state != .podding {
                
                delegate?.onPodding( at: next, podding: false )
                videoDelegate?.didExitPodding()

            }

        } else {
            
            delegate?.onNewAudience( at: next, didJoin: next.state != .notHere )
            postRefreshClubs( at: self.clubID )

            // if new audience wants to speak, alert
            if next.state == .raisedHand {
                delegate?.onRaiseHand( at: next, raised: true )
            }
            
            if next.state == .speaking {
                delegate?.onNewOnStage( at: next, on: true )
            }
            
            if next.state == .moderating {
                delegate?.onNewModerator( at: next, isMod: true )
            }
            
            if next.state == .podding {
                delegate?.onPodding( at: next, podding: true )
            }
            
            delegate?.didChangeMute(at: next, to: next.muted)
            if next.muted {
                postDidMute( userID: user.uuid, roomID: self.uuid )
                postDidUnSpeaking(userID: user.uuid, roomID: self.uuid)
            } else {
                postDidUnMute( userID: user.uuid, roomID: self.uuid )
            }
            
        }
    }
}


