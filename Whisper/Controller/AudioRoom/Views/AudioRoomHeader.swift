//
//  AudioRoomHeader.swift
//  byte
//
//  Created by Xiao Ling on 1/9/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

protocol AudioRoomHeaderDelegate {
    func onHandleDismiss() -> Void
    func onHandleSetting() -> Void
    func onShareNumber() -> Void
}

class AudioRoomHeader : UIView {
    
    var delegate: AudioRoomHeaderDelegate?
    
    var club: Club?
    var room: Room?
    
    var add: TinderButton?
    var share: TinderButton?
    var backBtn: TinderButton?
    var setting: TinderButton?
    var prevHt: CGFloat = 0
    var lastOpen: Int = now()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MARK:- API

    func config( with club: Club?, room: Room? ){
        self.room = room
        self.club = club
        if let room = room {
            if room.isRoot {
                layout()
            } else {
                layoutSimple()
            }
        } else {
            layoutSimple()
        }
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        return
    }
    
    func refresh(){
        guard let club = club else { return }
        if club.locked {
            setting?.changeImage(to: "hidden")
        } else {
            setting?.changeImage(to: "hidden-false")
        }
    }
    
    //MARK:- events
    
    @objc func onBell(_ button: TinderButton ){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 ) { [weak self] in
            self?.delegate?.onHandleSetting()
        }
    }

    @objc func onAdd(_ button: TinderButton ){
        return
    }

    @objc func onShare(_ button: TinderButton ){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 ) { [weak self] in
            self?.delegate?.onShareNumber()
        }
    }

    @objc func onProfile(_ button: TinderButton ){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 ) { [weak self] in
            self?.delegate?.onHandleDismiss()
        }
    }
    
    //MARK:- view
    
    private func layoutSimple(){
        
        let f = self.frame
        let label = UILabel()
        label.frame = CGRect(x: 20, y:0, width: f.width-40, height: f.height)
        label.textAlignment = .left
        label.textColor = Color.primary_dark
        label.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        label.text = "Breakout Room"
        addSubview(label)
        if let user = UserList.shared.get(room?.createdBy) {
            label.text = "\(user.get_H1())'s Breakout Room"
        }
    }
    
    
    /*
     @use: place image,text, and two pills
    */
    private func layout(){

        let f = self.frame
        let R = CGFloat(40)
            
        // iconR
        let backBtn = TinderButton()
        backBtn.frame = CGRect(x:20,y:(f.height-R)/2+5, width:R, height:R)
        backBtn.changeImage( to: "down", scale: 1/3)
        backBtn.addTarget(self, action: #selector(onProfile), for: .touchUpInside)
        addSubview(backBtn)
        backBtn.backgroundColor = Color.graySecondary
        self.backBtn = backBtn
        
        // name
        let label = UILabel()
        label.frame = CGRect(x: 20+R, y:0, width: f.width-2*(20+R)-20, height: f.height)
        label.textAlignment = .center
        label.textColor = Color.primary_dark
        label.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        label.text = "Main Room"
        label.center.x = self.center.x
        addSubview(label)
        
        if let club = self.club {
            if club.type == .ephemeral{
                label.text = "One-time"
            } else {
                label.text = "Main"
            }
            
        }
        
        if let backBtn = self.backBtn {
            label.center.y = backBtn.center.y
        }
        
        showSettings( with: club )
    }

    
    func showSettings( with club: Club? ){
        
        if let _ = self.setting { return }
        
        var str = "pin-2"
        if let club = club {
            switch club.type {
            case .home:
                str = "fire"
            case .ephemeral:
                str = "timer-2"
            case .cohort:
                str = "pin-l"
            /*default:
                if club.locked {
                    str = "hidden"
                } else {
                    str = "hidden-false"
                }
            }*/
            }
        }

        let f = self.frame
        let R = CGFloat(40)
        
        // icon R
        let btn = TinderButton()
        btn.frame = CGRect(x:f.width-20-R,y:(f.height-R)/2+5, width:R, height:R)
        btn.changeImage( to: str )
        btn.alpha = 0.0
        btn.backgroundColor = Color.graySecondary
        btn.addTarget(self, action: #selector(onBell), for: .touchUpInside)
        addSubview(btn)
        self.setting = btn
        
        func fn(){ btn.alpha = 1.0 }
        runAnimation( with: fn, for: 0.25 ){}
        
    }
    
    func removeAdd(){
        add?.removeFromSuperview()
        self.add = nil
    }



    
}
