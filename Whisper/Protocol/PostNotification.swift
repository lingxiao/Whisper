//
//  PostNotification.swift
//  byte
//
//  Created by Xiao Ling on 7/13/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



//MARK:-  decode notification payload


func decodePayload( _ notification: NSNotification ) -> String? {

    guard let payload = notification.userInfo
        else { return nil }

    if let gid = payload["String"] as? String {
        return gid
    } else {
        return nil
    }
}

func decodePayloadForUserID( _ notification: NSNotification ) -> UserID? {

    guard let payload = notification.userInfo
        else { return nil }

    if let uid = payload["userID"] as? String {
        return uid
    } else {
        return nil
    }
}

func decodePayloadForMessageID( _ notification: NSNotification ) -> String? {

    guard let payload = notification.userInfo
        else { return nil }

    if let uid = payload["messageID"] as? String {
        return uid
    } else {
        return nil
    }
}

func decodePayloadForField( field: String, _ notification: NSNotification ) -> UserID? {

    guard let payload = notification.userInfo
        else { return nil }

    if let uid = payload[field] as? String {
        return uid
    } else {
        return nil
    }
}


//MARK:- awake with call


// @use: when the phone awake from push notification, send
func postCallFromPushAwake( for gid: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "onCallFromNotification")
        , object: nil
        , userInfo: ["String": gid, "mode": "host" ]
    )
}

// @use: listen for this event
func listenForCallFromPushAwake( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "onCallFromNotification")
        , object: nil
    )
}

//MARK:- awake with live invite

// @use: when the phone awake from push notification, send
func postLiveInviteFromPushAwake( for uid: UserID ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "onLiveInviteFromNotification")
        , object: nil
        , userInfo: ["userID": uid, "mode": "guest" ]
    )
}

// @use: listen for this event
func listenForLiveInviteFromPushAwake( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "onLiveInviteFromNotification")
        , object: nil
    )
}

//MARK:- i did join or leave room

// @use: when the phone awake from push notification, send
func postIdidJoinOrLeaveRoom( at roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postIdidJoinOrLeaveRoom")
        , object: nil
        , userInfo: ["String": roomID ]
    )
}

// @use: listen for this event
func listenIdidJoinOrLeaveRoom( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postIdidJoinOrLeaveRoom")
        , object: nil
    )
}


// MARK:- mute and unmute

// @Use: post for when new comment added
func postDidMute( userID: String, roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidMute")
        , object: nil
        , userInfo: ["userID": userID, "roomID": roomID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidMute( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidMute")
        , object: nil
    )
}



// @Use: post for when new comment added
func postDidUnMute( userID: String, roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidUnMute")
        , object: nil
        , userInfo: ["userID": userID, "roomID": roomID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidUnMute( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidUnMute")
        , object: nil
    )
}

// MARK:- Speaking and unSpeaking

// @Use: post for when new comment added
func postDidSpeaking( userID: String, roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidSpeaking")
        , object: nil
        , userInfo: ["userID": userID, "roomID": roomID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidSpeaking( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidSpeaking")
        , object: nil
    )
}



// @Use: post for when new comment added
func postDidUnSpeaking( userID: String, roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidUnSpeaking")
        , object: nil
        , userInfo: ["userID": userID, "roomID": roomID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidUnSpeaking( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidUnSpeaking")
        , object: nil
    )
}

//MARK:- follow state change

func postDidFollow( userID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidFollow")
        , object: nil
        , userInfo: ["userID": userID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidFollow( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidFollow")
        , object: nil
    )
}



// @Use: post for when new comment added
func postDidUnFollow( userID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidUnFollow")
        , object: nil
        , userInfo: ["userID": userID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidUnFollow( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidUnFollow")
        , object: nil
    )
}

//MARK:- block

func postDidBlockMe( userID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postDidBlockMe")
        , object: nil
        , userInfo: ["userID": userID]
    )
}


// @use: listen for when a new comment has been added
func listenForDidBlockMe( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postDidBlockMe")
        , object: nil
    )
}

func postIdidBlock( userID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postIdidBlock")
        , object: nil
        , userInfo: ["userID": userID]
    )
}


// @use: listen for when a new comment has been added
func listenIdidBlock( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postIdidBlock")
        , object: nil
    )
}


// MARK:- deleted room

// @Use: post for when new comment added
func postRoomDidDelete( roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postRoomDidDelete")
        , object: nil
        , userInfo: ["String": roomID]
    )
}


// @use: listen for when a new comment has been added
func listenRoomDidDelete( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postRoomDidDelete")
        , object: nil
    )
}

// @Use: post for when new comment added
func postBreakoutRoomDidAdd( roomID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postBreakoutRoomDidAdd")
        , object: nil
        , userInfo: ["String": roomID]
    )
}


// @use: listen for when a new comment has been added
func listenBreakoutRoomDidAdd( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postBreakoutRoomDidAdd")
        , object: nil
    )
}


//MARK:- resfresh alert

// @use: when the phone awake from push notification, send
func postFreshAlerts(){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postRefreshAlerts")
        , object: nil
        , userInfo: ["userID": ""]
    )
}

// @use: listen for this event
func listenFreshAlerts( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postRefreshAlerts")
        , object: nil
    )
}

//MARK:- resfresh club directory

// @use: when the phone awake from push notification, send
func postRefreshClubs( at clubID: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postRefreshClubs")
        , object: nil
        , userInfo: ["String": clubID ]
    )
}

// @use: listen for this event
func listenRefreshClubs( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postRefreshClubs")
        , object: nil
    )
}

// @use: when the phone awake from push notification, send
func postRefreshClubPage( at id: String ){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postRefreshClubPage")
        , object: nil
        , userInfo: ["String": id ]
    )
}

// @use: listen for this event
func listenRefreshClubPage( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postRefreshClubPage")
        , object: nil
    )
}

//MARK:- ptr from ClubPageController

// @use: when the phone awake from push notification, send
func postClubPagePTR(){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postClubPagePTR")
        , object: nil
        , userInfo: ["String": "" ]
    )
}

// @use: listen for this event
func listenClubPagePTR( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postClubPagePTR")
        , object: nil
    )
}


//MARK:- ptr from ClubPageController

// @use: when the phone awake from push notification, send
func postRefreshNewsFeed(){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postRefreshNewsFeed")
        , object: nil
        , userInfo: ["String": "" ]
    )
}

// @use: listen for this event
func listenRefreshNewsFeed( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postRefreshNewsFeed")
        , object: nil
    )
}



//MARK:- resfresh profile

// @use: when the phone awake from push notification, send
func postRefreshProfile(){
    NotificationCenter.default.post(
          name: Notification.Name(rawValue: "postRefreshProfile")
        , object: nil
        , userInfo: ["userID": ""]
    )
}

// @use: listen for this event
func listenRefreshProfile( on obj: Any, for listener: Selector ){
    NotificationCenter.default.addObserver(
          obj
        , selector: listener
        , name: Notification.Name(rawValue: "postRefreshProfile")
        , object: nil
    )
}
