//
//  AudioRoomModal.swift
//  byte
//
//  Created by Xiao Ling on 12/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


protocol AudioRoomModalDelegate {
    func onHandleAlertMe( with club: Club, at room: Room?, for user: User ) -> Void
    func onHandleRemove( with club: Club, at room: Room?, for user: User ) -> Void
    func onSitDown( for user: User? ) -> Void
    func onAddToGroup( for user: User? ) -> Void
    func onHandleGoToProfile( to user: User ) -> Void
}

class AudioRoomModal: UIView {
    
    // data
    var club : Club?
    var room : Room?
    var user : User?
    var delegate: AudioRoomModalDelegate?
    
    //style
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height( _ club: Club?, _ user: User? ) -> CGFloat {

        guard let club = club else { return 0.0 }
        guard let user = user else { return 0.0 }
        
        if user.isMe() {
            var dy: CGFloat = 10
            dy += AppFontSize.H1 + 10
            dy += 40 + 10
            dy += 20
            return dy

        } else if club.iamAdmin() {

            var dy: CGFloat = 10
            dy += AppFontSize.H1 + 10
            dy += 40 + 10
            dy += 40 + 10
            dy += 40 + 10
            dy += 40 + 10
            dy += 20
            return dy

        } else {

            var dy: CGFloat = 10
            dy += AppFontSize.H1 + 10
            dy += 40 + 10
            dy += 40 + 10
            dy += 40 + 10
            dy += 20
            return dy
        }

    }
    
    func config( with club: Club?, at room: Room?, for user: User?, width: CGFloat ){

        self.club   = club
        self.user   = user
        self.room   = room
        self.width  = width

        guard let club = club else { return }
        guard let room = room else { return }
        guard let user = user else { return }

        if user.isMe() {
            layoutIsMe(club, room, user)
        } else if club.iamAdmin() {
            layoutAdmin(club, room, user)
        } else {
            layoutGuest(club, room, user)
        }

    }
    
    
    @objc func onHandleAdmin(_ button: TinderButton ){
        if let club = self.club {
            if let user = self.user {
                delegate?.onHandleAlertMe(with: club, at: self.room, for: user)
            }
        }
    }

    @objc func onHandleRemove(_ button: TinderButton ){
        if let club = self.club {
            if let user = self.user {
                delegate?.onHandleRemove(with: club, at: self.room, for: user)
            }
        }
    }

    @objc func onHandleNavToProfile(_ button: TinderButton ){
        if let user = self.user {
            delegate?.onHandleGoToProfile(to: user)
        }
    }

    @objc func onSitDown(_ button: TinderButton ){
        if let user = self.user {
            delegate?.onSitDown(for: user)
        }
    }
    
    @objc func onAddToGroup(_ button: TinderButton ){
        if let user = self.user {
            delegate?.onAddToGroup(for: user)
        }
    }

    //MARK:- view
    
    private func layoutAdmin( _ club: Club, _ room: Room, _ user: User ){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  AudioRoomModal.height(club, user)))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        let btnW = width*2/3
        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)

        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = user.get_H1()
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 20
        
        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-btnW)/2, y:dy,width:btnW,height:40)
        btn.config(with: "Alert me if \(user.get_H1()) is in room" )
        btn.backgroundColor = Color.graySecondary
        btn.textLabel?.textColor = Color.primary_dark
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleAdmin)))

        dy += 40 + 10
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: (width-btnW)/2, y:dy,width:btnW,height:40)
        btn2.config(with: "Remove \(user.get_H1()) from room" )
        btn2.backgroundColor = Color.graySecondary
        btn2.textLabel?.textColor = Color.primary_dark
        btn2.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn2)
        btn2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleRemove)))

        dy += 40 + 10
        
        var str = ""
        
        if let record = room.getMember(user.uuid) {
            if record.state == .speaking {
                str = "Sit \(user.get_H1()) down"
            } else {
                str = "Bring \(user.get_H1()) on stage"
            }
        }

        let btn3 = TinderTextButton()
        btn3.frame = CGRect(x: (width-btnW)/2, y:dy,width:btnW,height:40)
        btn3.config(with: str )
        btn3.backgroundColor = Color.graySecondary
        btn3.textLabel?.textColor = Color.primary_dark
        btn3.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn3)
        btn3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSitDown)))

        dy += 40 + 10
        
        let btn4 = TinderTextButton()
        btn4.frame = CGRect(x: (width-btnW)/2, y:dy,width:btnW,height:40)
        btn4.config(with: "See profile")
        btn4.backgroundColor = Color.graySecondary
        btn4.textLabel?.textColor = Color.primary_dark
        btn4.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn4)
        btn4.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleNavToProfile)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }

    private func layoutGuest( _ club: Club, _ room: Room, _ user: User ){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  AudioRoomModal.height(club, user)))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        let btnW = width*2/3
        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)

        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = user.get_H1()
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 20
        
        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-btnW)/2, y:dy,width:btnW,height:40)
        btn.config(with: "Alert me if \(user.get_H1()) is in room" )
        btn.backgroundColor = Color.graySecondary
        btn.textLabel?.textColor = Color.primary_dark
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleAdmin)))

        dy += 40 + 10
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn2.config(with: "Invite \(user.get_H1()) to my group")
        btn2.backgroundColor = Color.graySecondary
        btn2.textLabel?.textColor = Color.primary_dark
        btn2.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn2)
        btn2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAddToGroup)))

        dy += 40 + 10
        
        let btn4 = TinderTextButton()
        btn4.frame = CGRect(x: (width-btnW)/2, y:dy,width:btnW,height:40)
        btn4.config(with: "See profile")
        btn4.backgroundColor = Color.graySecondary
        btn4.textLabel?.textColor = Color.primary_dark
        btn4.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn4)
        btn4.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleNavToProfile)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }


    private func layoutIsMe( _ club: Club, _ room: Room, _ user: User ){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  AudioRoomModal.height(club,user)))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)

        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = user.get_H1()
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 20
        
        // add button
        var str = "Sit down"
        
        if let rec = room.getMyRecord() {
            if rec.state == .speaking {
                str = "Sit down"
            } else if rec.state == .podding {
                str = "Dismiss"
            } else {
                if club.iamAdmin() || club.iCanSpeakInRooms() {
                    str = "Speak"
                } else {
                    str = "Raise hand"
                }
            }
        }
        
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-width/2)/2,y:dy,width:width/2,height:40)
        btn.config(with: str)
        btn.backgroundColor = Color.graySecondary
        btn.textLabel?.textColor = Color.primary_dark
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSitDown)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }

    
}
