//
//  Core.swift
//  byte
//
//  Created by Xiao Ling on 5/17/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


//MARK:- constants

let APP_NAME = "Whisper"

// App ID for agora dev mode
let AppID : String = "08d14d4f1e6d4aeaa14a0c8b07776177"

let MAX_NAME_EDITS : Int = 1000

// demo flags
let GLOBAL_DEMO = false
let GLOBAL_SHOW_DEMO_PROFILE = false

//MARK: - type alias

typealias UserID     = String
typealias ClubID     = String
typealias RoomID     = String
typealias PodID      = String
typealias CardID     = String
typealias DeckID     = String

typealias PushToken  = String
typealias UniqueID   = String
typealias AgoraID    = UInt


typealias Completion          = (Bool,String) -> Void
typealias CompletionUserList  = (Bool,String,[User] ) -> Void

typealias MetaData      = [String:String]
typealias FirestoreData = [String:Any]


// push notification action
struct PUSH_ACTION {
    static let invite_guest_push_wake = "INVITE_GUEST_TO_PUSH_WAKE"
    static let did_comment_on_scheduled = "did_comment_on_scheduled"
}


enum StyleMode {
    case light
    case dark
}


//MARK: - user authed state

enum UserAuthedState {
    case locked
    case hereToBid
    case hereToSell
    case unlocked
}

func fromUserAuthedState( _ st: UserAuthedState ) -> String {
    switch ( st ){
    case .locked:
        return "locked"
    case .hereToBid:
        return "hereToBid"
    case .hereToSell:
        return "hereToSell"
    case .unlocked:
        return "unlocked"
    }
}


func toUserAuthedState( _ st: String ) -> UserAuthedState {
    switch ( st ){
    case "locked":
        return .locked
    case "hereToBid":
        return .hereToBid
    case "hereToSell":
        return .hereToSell
    case "unlocked":
        return .unlocked
    default:
        return .locked
    }
}

//MARK: - room state

enum CallState {
    case ended
    case liveHostAudio
    case liveHostVideo
    case liveGuest
}

func stateCall( _ st: CallState ) -> String {
    switch ( st ){
    case .ended:
        return "ended"
    case .liveHostAudio:
        return "liveHostAudio"
    case .liveHostVideo:
        return "liveHostVideo"
    case .liveGuest:
        return "liveGuest"
    }
}


func toCallState( _ st: String ) -> CallState {
    switch ( st ){
    case "ended":
        return .ended
    case "liveHostAudio":
        return .liveHostAudio
    case "liveHostVideo":
        return .liveHostVideo
    case "liveGuest":
        return .liveGuest
    default:
        return .ended
    }
}


//MARK:- social limits

enum SocialLimit {
    case open
    case cannotSeeMyLiveEvent
}


/*
 @Use: convert to code for FirestoreData query
*/
func limitSocial( _ social: SocialLimit? ) -> String {
     
    guard let soc = social else {
        return ""
    }

    switch(soc){
    case SocialLimit.open:
        return "open"
    case SocialLimit.cannotSeeMyLiveEvent:
        return "cannotSeeMyLiveEvent"
    }
}

func socialLimit( _ val: String? ) -> SocialLimit {

    guard let soc = val else {
        return SocialLimit.open
    }

    switch(soc){
    
    case "open":
        return SocialLimit.open
    case "cannotSeeMyLiveEvent":
        return SocialLimit.cannotSeeMyLiveEvent
    default:
        return SocialLimit.open
    }
    
}



//MARK:- Bid to join org

struct OrgBid {
    var uuid     : String
    var user     : User
    var timeStamp: Int
    var latest   : Int
    var bidInCents: Int
    var canceled  : Bool
}

extension OrgBid : Equatable {
    static func == (lhs: OrgBid, rhs: OrgBid) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

// decode org bid and render
func decodeOrgBid( _ blob : FirestoreData?, _ then: @escaping(OrgBid?) -> Void ){
    
    guard let data = blob else { return then(nil) }
    
    guard let uuid = data["userID"] as? String else { return then(nil) }
    if uuid == "" { return then(nil) }
    
    UserList.shared.pull(for: uuid){ (_,_,user) in
        guard let user = user else { return then(nil) }
        let mem = OrgBid(
            uuid      : uuid,
            user      : user,
            timeStamp : unsafeCastInt(data["timestamp"]),
            latest    : unsafeCastInt(data["latest"]),
            bidInCents: unsafeCastIntToZero(data["bidInCents"]),
            canceled  : unsafeCastBool(data["canceled"])
        )
        return then(mem)
    }
}




//MARK:- room permission

enum ClubType {
    case home
    case cohort
    case ephemeral
}

func clubType( _ perm: String ) -> ClubType {

    switch (perm){
    case "home":
        return .home
    case "ephemeral":
        return .ephemeral
    default:
        return .cohort
    }
}


func typeClub( _ perm: ClubType ) -> String {
    switch(perm){
    case .home:
        return "home"
    case .ephemeral:
        return "ephemeral"
    case .cohort:
        return "cohort"
    }
}


//MARK:- permission of club members

enum ClubPermission {
    case levelA
    case levelB
    case levelC
    case blocked
}

func fromClubPermission( _ perm : ClubPermission ) -> String {
    switch perm {
    case .levelA:
        return "levelA"
    case .levelB:
        return "levelB"
    case .levelC:
        return "levelC"
    case .blocked:
        return "blocked"
    }
}

func toClubPermission( _ str: String) -> ClubPermission {
    switch str {
    case "levelA":
        return .levelA
    case "levelB":
        return .levelB
    case "levelC":
        return .levelC
    case "blocked":
        return .blocked
    default:
        return .levelC
    }
}


//MARK:- member blob

struct ClubMember {

    var uuid: String
    var user: User
    
    // time
    var timeStamp: Int
    var latest   : Int
    
    // social
    var iamFollowing : Bool
    var isFollowingMe: Bool
    var permission   : ClubPermission

    // payment
    var monthlyPayment: Int
    var didPayThisMonth: Bool

    // stats
    var num_down    : Int
    var num_up      : Int
    var num_speak   : Int
    var num_session : Int

}

extension ClubMember : Equatable {
    static func == (lhs: ClubMember, rhs: ClubMember) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

func makeMemberStub(_ uid: UserID ) -> FirestoreData {
    
    let res : FirestoreData = [
        
        "userID"     : uid,
        "timeStamp"  : now(),
        "latest"     : now(),
            
        "monthlyPayment" : 0,
        "didPayThisMonth": false,
        
        "iamFollowing" : false,
        "isFollowingMe": false,
        "permission"   : fromClubPermission(.levelA),
        
        "num_down"   : 0,
        "num_up"     : 0,
        "num_speak"  : 0,
        "num_session": 0,
    ]
    
    return res
}


func decodeClubMember( _ blob : FirestoreData?, _ then: @escaping(ClubMember?) -> Void ){
    
    guard let data = blob else { return then(nil) }
    
    guard let uuid = data["userID"] as? String else { return then(nil) }
    if uuid == "" { return then(nil) }
    
    UserList.shared.pull(for: uuid){ (_,_,user) in
        
        guard let user = user else { return then(nil) }
        
        let mem = ClubMember(uuid: uuid,
            user: user,
            timeStamp: unsafeCastInt(data["timestamp"]),
            latest: unsafeCastInt(data["latest"]),
            iamFollowing: unsafeCastBool(data["iamFollowing"]),
            isFollowingMe:  unsafeCastBool(data["isFollowingMe"]),
            permission: toClubPermission(unsafeCastString(data["permission"])),

            monthlyPayment: unsafeCastInt(data["monthlyPayment"]),
            didPayThisMonth: unsafeCastBool(data["didPayThisMonth"]),

            num_down: unsafeCastInt(data["num_down"]),
            num_up: unsafeCastInt(data["num_up"]),
            num_speak: unsafeCastInt(data["num_speak"]),
            num_session: unsafeCastInt(data["num_session"])
        )
        
        return then(mem)
    }
}



//MARK:- stucts: room audience

enum RoomMemberState {
    case notHere
    case podding
    case listening
    case raisedHand
    case speaking
    case moderating
}

func fromRoomMemberState( _ st : RoomMemberState ) -> String {
    switch st {
    case .speaking:
        return "speaking"
    case .moderating:
        return "moderating"
    case .listening:
        return "listening"
    case .raisedHand:
        return "raisedHand"
    case .podding:
        return "podding"
    case .notHere:
        return "notHere"
    }
}

func toRoomMemberState( _ str: String ) -> RoomMemberState {
    switch str {
    case "speaking":
        return .speaking
    case "moderating":
        return .moderating
    case "listening":
        return .listening
    case "raisedHand":
        return .raisedHand
    case "podding":
        return .podding
    default:
        return .notHere
    }
}

struct RoomMember {

    var uuid: String
    var user: User
    var timeStamp: Int
    var joinedTime: Int

    // member state
    var state : RoomMemberState
    var symbol    : String
    var agoraTok  : String
    var muted     : Bool
    var currPod   : PodID
    var beat: Int

}

extension RoomMember : Equatable {
    static func == (lhs: RoomMember, rhs: RoomMember) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}


func makeRoomMemberStub(_ uid: UserID ) -> FirestoreData {
    
    let res : FirestoreData = [
        "userID"    : uid,
        "timeStamp" : now(),
        "joinedTime": now(),
        "state"     : fromRoomMemberState(.notHere),
        "symbol"    : "",
        "agoraTok"  : "",
        "muted"     : true,
        "currPod"   : "",
        "beat"      : ThePast()
    ]
    
    return res
}


func decodeRoomMember( _ blob : FirestoreData?, _ then: @escaping(RoomMember?) -> Void ){
    
    guard let data = blob else { return then(nil) }
    
    guard let uuid = data["userID"] as? String else { return then(nil) }
    if uuid == "" { return then(nil) }
    
    UserList.shared.pull(for: uuid){ (_,_,user) in
        
        guard let user = user else { return then(nil) }
        
        let mem = RoomMember(
            uuid      : uuid,
            user      : user,
            timeStamp : unsafeCastInt(data["timestamp"]),
            joinedTime: unsafeCastInt(data["joinedTime"]),
            state     : toRoomMemberState( unsafeCastString(data["state"])),
            symbol    : unsafeCastString(data["symbol"]),
            agoraTok  : unsafeCastString(data["agoraTok"]),
            muted     : unsafeCastBool(data["muted"]),
            currPod   : unsafeCastString(data["currPod"]),
            beat      : unsafeCastInt(data["beat"])
        )
        
        return then(mem)
        
    }
}


//MARK:- alerts

enum AlertKind {

    case none
    case follow
    case alertMe
    case inviteToGroup
    case joinGroup
    
    case paymentFailed
    case paymentSuccess
}

struct AlertBlob {
    var ID: String
    var seen: Bool
    var text: String
    var source: User
    var kind  : AlertKind
    var meta  : String
    var timeStamp: Int
}

extension AlertBlob : Equatable {
    static func == (lhs: AlertBlob, rhs: AlertBlob) -> Bool {
        return lhs.ID == rhs.ID
    }
}


func fromAlert( _ alert: AlertKind ) -> String {
    switch(alert){
    case .follow:
        return "follow"
    case .alertMe:
        return "alertMe"
    case .inviteToGroup:
        return "inviteToGroup"
    case .joinGroup:
        return "joinGroup"
    case .paymentFailed:
        return "paymentFailed"
    case .paymentSuccess:
        return "paymentSuccess"
    default:
        return ""
    }
}


func toAlert( _ str : String ) -> AlertKind {
    
    switch (str){
    case "follow":
        return .follow
    case "alertMe":
        return .alertMe
    case "inviteToGroup":
        return .inviteToGroup
    case "joinGroup":
        return .joinGroup
    case "paymentFailed":
        return .paymentFailed
    case "paymentSuccess":
        return .paymentSuccess
    default:
        return .none
    }
}

func setAlert( for uid: UserID?, kind : AlertKind?, meta: String = "" ){
    
    guard let uid = uid else { return }
    guard let kind = kind else { return }
    if UserAuthed.shared.uuid == uid { return }
    
    if uid == "" { return }
    let ID =  UUID().uuidString
    
    let blob : FirestoreData = [
        "source": UserAuthed.shared.uuid,
        "target": uid,
        "kind"  : fromAlert(kind),
        "meta"  : meta,
        "timeStamp": now(),
        "seen"  : false,
        "alertID": ID
    ]
    
    UserAuthed.alertCol()?.document(ID).setData(blob){ _ in return }

}



func decodeAlert( _ blob : FirestoreData?, _ then: @escaping(AlertBlob?) -> Void ){
    
    guard let data = blob else { return then(nil) }
    
    let id     = unsafeCastString(data["alertID"])
    let time   = unsafeCastInt(data["timeStamp"])
    let seen   = unsafeCastBool(data["seen"])
    let source = unsafeCastString(data["source"])
    let kind   = toAlert(unsafeCastString(data["kind"]))
    let meta   = unsafeCastString(data["meta"])

    if id == "" || source == "" { return then(nil) }
    
    UserList.shared.pull(for: source){(_,_,src) in

        guard let src = src else { return then(nil) }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            
            var str = ""
            let name = src.get_H1()
            
            switch kind {
            case .follow:
                str = "\(name) joined \(APP_NAME). Tap here to go to \(name)'s profile"
            case .alertMe:
                str = "\(name) wants to be alerted when you are live. Tap the bell button to be alerted when \(name) is live as well."
            case .inviteToGroup:
                str = "\(name) has invited you to join a private channel. Tap the button to accept."
            case .joinGroup:
                str = "\(name) just joined your channel, you can now ping this person into the room when you hold future events."
            case .paymentFailed:
                str = "Payment failed: \(meta)"
            case .paymentSuccess:
                str = "Payment succeeded: \(meta)"
            default:
                break;
            }
            
            let data = AlertBlob(
                ID    : id,
                seen  : seen,
                text  : str,
                source: src,
                kind  : kind,
                meta  : meta,
                timeStamp: time
            )

            return then( data )
        }

    }


}


