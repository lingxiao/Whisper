//
//  Pipe.swift
//  byte
//
//  Created by Xiao Ling on 5/21/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


//MARK:- protcol for model to push update to controllers and views

/*
 @Note: conceptually we have:
     type Source a      ==> database
     type Pipe a b      ==> model/controllers
     type Sink b        ==> view
 */

/*
 @Use: each pipe can await from upstream producer, and yield to downstream pipe or consumer
*/
protocol Pipe {
    func await() -> Void
    func yield( to: Any, with listener: Selector ) -> Void
}



///*
// @Use: sources can only yield
//*/
protocol source {
    func yield( to: Any, with listener: Selector) -> Void
}

/*
 @Use: sinks can only await data. Views are sinks
*/
protocol Sink {
    func await() -> Void
}

//MARK:- permission delegate

protocol PermissionDelegate {
    func didBlock( blocker src: UserID, blocked tgt: UserID ) -> Void
}


//MARK:- User Delegate

// delegate for authenticated user ( mysself )
protocol AuthedUserDelegate {
    func didEarnCoins( amt : Int ) -> Void
    func shouldEnterBankAccount() -> Void
    func didReceiveNewAlert( at alert: AlertBlob ) -> Void
}

protocol RoomDelegate {

    // room states
    func didChangeRoomPerm( perm: RoomPerm ) -> Void

    // room states
    func didLiveHostAudio () -> Void
    func didExitLive( from room: Room ) -> Void

    func didStartRecord() -> Void
    func didEndRecord()   -> Void

    // session audience states
    func onNewAudience   ( at user: RoomMember, didJoin: Bool  ) -> Void
    func onNewOnStage    ( at user: RoomMember, on stage: Bool ) -> Void
    func onNewModerator  ( at user: RoomMember, isMod: Bool    ) -> Void
    func didChangeMute   ( at user: RoomMember, to muted: Bool ) -> Void
    func onRaiseHand     ( at user: RoomMember, raised: Bool   ) -> Void
    func onPodding       ( at user: RoomMember, podding: Bool  ) -> Void
    
    func onNewChatItem( in room: Room, with: RoomChatItem ) -> Void
    func onTypingNewChat( in room: Room ) -> Void
    
}

protocol RoomChatDelegate {
    func didChangeText( to str: String, by user: User? ) -> Void
}

protocol RoomVideoDelegate {
    func didExitPodding() -> Void
    func didEnterPodding() -> Void
}

//MARK:- club delegates

protocol ClubDelegate {
    func didChangeLock( to locked: Bool ) -> Void
    func didAddPlayList() -> Void
    func didChangeWidgets() -> Void
    func didDeleteClub( at club: Club ) -> Void
}



protocol ClubPlaylistDelegate {
    func didExitLive( for club : Club ) -> Void
    func didGoLive( for club : Club ) -> Void
    func didChangeTopic( for club: Club ) -> Void
}


