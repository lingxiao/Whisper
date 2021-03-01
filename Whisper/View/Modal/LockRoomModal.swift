//
//  LockRoomModal.swift
//  byte
//
//  Created by Xiao Ling on 1/27/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit

protocol LockRoomModalDelegate {
    func onToggleLockRoom() -> Void
}

class LockRoomModal: UIView {
    
    // data
    var club : Club?
    
    //style
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    var delegate: LockRoomModalDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        var dy: CGFloat = 20
        dy += AppFontSize.H2 + 10
        dy += AppFontSize.H2 + 20
        dy += 40 + 10
        return dy
    }
    
    func config( with club: Club?, width: CGFloat ){
        self.club   = club
        self.width  = width
        if let club = club { layout(club) }
    }
    
    
    @objc func handleBtn(_ button: TinderButton ){
        SwiftEntryKit.dismiss()
        delegate?.onToggleLockRoom()
    }
    
    private func layout( _ club: Club ){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  LockRoomModal.height()))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.white
        addSubview(parent)
        
        var dy: CGFloat = 10
        let font = UIFont(name: FontName.bold, size: AppFontSize.footer)

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.white
        parent.addSubview(v)
        
        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h1.font = font
        h1.text = ""
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.white
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H2 + 10
        
        // add explain
        let h2 = UITextView(frame:CGRect(x:20,y:dy,width:width-40, height:AppFontSize.H2))
        h2.font = font
        h2.text = ""
        h2.textColor = Color.primary_dark
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = Color.white
        h2.isUserInteractionEnabled = false
        parent.addSubview(h2)
        
        dy += AppFontSize.H2 + 20
        
        var str = ""
        let orgName = club.getOrg()?.get_H1() ?? "this board"

        if club.type == .home {
            str = "Dismiss"
            h1.text = "Home room is visible to everyone in \(orgName)"
            h2.text = "This is the spot to hold bigger events"
        } else if club.type == .ephemeral {
            str = "Dismiss"
            h1.text = "Ephemeral room"
            h2.text = "This room will disappear when its creator leaves."
        } else {
            if club.iamAdmin() {
                if club.locked {
                    str = "Unhide"
                    h1.text = "This channel is hidden"
                    h2.text = "Only channel members can find and join this room"
                } else {
                    str = "Hide"
                    h1.text = "This channel is open"
                    h2.text = "Anyone from \(orgName) can join this room"
                }
            } else {
                str = "Dismiss"
            }
        }

        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn.config(with: str, color: Color.primary_dark, font: font)
        btn.backgroundColor = Color.graySecondary
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBtn)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.white
        parent.addSubview(vb)
    }

}
