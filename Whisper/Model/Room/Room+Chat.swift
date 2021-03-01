//
//  Room+Chat.swift
//  byte
//
//  Created by Xiao Ling on 2/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase


struct RoomChatItem {
    var user: User
    var text: String
    var resolved: Bool
    var pressedEnter: Bool
    var timeStamp: Int
}

extension Room {
    
    func awaitChat(){
        Room.chatRef(for:self.uuid)?.addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            let str = unsafeCastString(data["text"])
            let uid = unsafeCastString(data["userID"])
            let resd = unsafeCastBool(data["resolved"])
            let pent = unsafeCastBool(data["pressedEnter"])
            let time = unsafeCastInt(data["timeStamp"])

            UserList.shared.pull(for: uid){(_,_,user) in
                guard let user = user else { return }
                let prevItem = self.chatItem

                let chatItem = RoomChatItem(user: user, text: str, resolved: resd, pressedEnter: pent, timeStamp: time)
                self.chatItem = chatItem
                self.chatDelegate?.didChangeText(to: str, by: user)
                
                if let prev = prevItem {
                    if chatItem.pressedEnter {
                        self.delegate?.onNewChatItem(in:self, with:chatItem)
                    } else if prev.user == chatItem.user && prev.text != chatItem.text {
                        self.delegate?.onTypingNewChat(in: self)
                    } else {
                    }
                }
            }
        }
    }
    
    func delChat(){
        Room.chatRef(for: self.uuid)?.delete()
    }
    
    func putText( str: String? ) -> Bool {

        guard let str = str else { return false }

        let res : FirestoreData = [
            "userID"      : UserAuthed.shared.uuid,
            "text"        : str,
            "timeStamp"   : now(),
            "resolved"    : false,
            "pressedEnter": false
        ]
        
        if unLocked(){
            Room.chatRef(for: self.uuid)?.setData(res){e in return }
            return true
        } else {
            return false
        }

    }
    
    func putEnter() -> Bool {
        if unLocked(){
            Room.chatRef(for: self.uuid)?.updateData(["pressedEnter":true,"timeStamp":now()]){e in return }
            return true
        } else {
            return false
        }
    }
    
    func putResolved() -> Bool {
        if unLocked() {
            Room.chatRef(for: self.uuid)?.updateData(["resolved":true,"timeStamp":now(),"text": ""]){e in return }
            return true
        } else {
            if let club = self.club {
                if club.iamAdmin() {
                    Room.chatRef(for: self.uuid)?.updateData(["resolved":true,"timeStamp":now(),"text": ""]){e in return }
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    private func unLocked() -> Bool {
        if let chat = self.chatItem {
            if chat.user.isMe() {
                return true
            } else {
                let txt = String(chat.text.filter { !" \n\t\r".contains($0) })
                if chat.resolved || chat.timeStamp > 60*10 {
                    return true
                } else if getAttending().count <= 1 {
                    return true
                } else if txt == "" {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return true
        }
    }
    
}
