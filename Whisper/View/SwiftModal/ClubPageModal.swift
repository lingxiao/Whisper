//
//  ClubPageModal.swift
//  byte
//
//  Created by Xiao Ling on 12/20/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


protocol ClubPageModalDelegate {
    func onHandleAdmin( with club: Club, for user: User ) -> Void
    func onHandleRemove( with club: Club, for user: User ) -> Void
    func onHandleNavToProfile( to user: User ) -> Void
}

class ClubPageModal: UIView {
    
    // data
    var club : Club?
    var user : User?
    var delegate: ClubPageModalDelegate?
    
    //style
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        var dy: CGFloat = 10
        dy += AppFontSize.H1 + 10
        dy += 40 + 10
        dy += 40 + 10
        dy += 40 + 10
        dy += 20
        return dy
    }
    
    func config( with club: Club?, for user: User?, width: CGFloat ){
        self.club   = club
        self.user   = user
        self.width  = width
        if let club = club {
            if let user = user {
                layout(club, user)
            }
        }
    }
    
    
    @objc func onHandleAdmin(_ button: TinderButton ){
        if let club = self.club {
            if let user = self.user {
                delegate?.onHandleAdmin(with: club, for: user)
            }
        }
    }

    @objc func onHandleRemove(_ button: TinderButton ){
        if let club = self.club {
            if let user = self.user {
                delegate?.onHandleRemove(with: club, for: user)
            }
        }
    }

    @objc func onHandleNavToProfile(_ button: TinderButton ){
        if let user = self.user {
            delegate?.onHandleNavToProfile(to: user)
        }
    }

    
    private func layout( _ club: Club, _ user: User ){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  ClubPageModal.height()))
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
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn.config(with: club.isAdmin(user) ? "Remove admin" : "Make admin" )
        btn.backgroundColor = Color.graySecondary
        btn.textLabel?.textColor = Color.primary_dark
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleAdmin)))

        dy += 40 + 10
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn2.config(with: "Remove \(user.get_H1())" )
        btn2.backgroundColor = Color.graySecondary
        btn2.textLabel?.textColor = Color.primary_dark
        btn2.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn2)
        btn2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleRemove)))

        dy += 40 + 10
        
        let btn3 = TinderTextButton()
        btn3.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn3.config(with: "See profile")
        btn3.backgroundColor = Color.graySecondary
        btn3.textLabel?.textColor = Color.primary_dark
        btn3.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn3)
        btn3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHandleNavToProfile)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }

}
