//
//  AlertCell.swift
//  byte
//
//  Created by Xiao Ling on 11/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol AlertCellDelegate {
    func onTapProfile( at user: User? ) -> Void
    func onFollow( at user: User? ) -> Void
    func onTapBtn( from alert: AlertBlob? ) -> Void
}

class AlertCell: UITableViewCell {
    
    static let identifier = "AlertCell"
    var delegate : AlertCellDelegate?

    // view
    var img: UIImageView?
    var label: UITextView?
    var nameFont: UIFont?
    var btn: TinderTextButton?
    var btn2: TinderButton?

    // data
    var alert: AlertBlob?
    var user: User?
    var hasBtn: Bool = false
    private var changing: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.btn?.removeFromSuperview()
        self.label?.removeFromSuperview()
    }
    
    func config( with alert : AlertBlob? ){
        
        guard let alert = alert else { return }
        if alert.text == "" { return }

        self.alert = alert
        self.user  = alert.source
        self.hasBtn = alert.kind == .follow
        
        layoutImage( btn: self.hasBtn )
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
        // listen to event
        listenForDidFollow(on: self, for: #selector(didFollow))
        listenForDidUnFollow(on: self, for: #selector(didUnFollow))

    }
        
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.onTapProfile(at: user)
    }
    
    @objc func handleBtn(_ button: TinderButton ){
        delegate?.onTapBtn(from: self.alert)
        func fn(){
            self.btn?.alpha = 0.0
            self.btn2?.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.75){
            self.btn?.removeFromSuperview()
            self.btn2?.removeFromSuperview()
            self.changing = false
            self.btn = nil
            self.btn2 = nil
        }
    }
    
    @objc func didFollow(_ notification: NSNotification){
        if isForMe(notification) == false || !hasBtn { return }
        btn?.textLabel?.text = "Followed"
        if changing { return }
        self.changing = true
        func fn(){ self.btn?.alpha = 0.0 }
        runAnimation( with: fn, for: 0.75){
            self.btn?.removeFromSuperview()
            self.changing = false
            self.btn = nil
        }
    }

    @objc func didUnFollow(_ notification: NSNotification){
        if isForMe(notification) == false || !hasBtn { return }
        layoutBtn()
    }
    

    private func isForMe(_ notification: NSNotification) -> Bool {
        guard let user = user else { return false }
        guard let uid = decodePayloadForField(field: "userID", notification) else { return false }
        return user.uuid == uid
    }
    
    //MARK:- view

    private func layoutImage( btn: Bool ){
        
        let R = CGFloat(40.0)
        let v = UIImageView(frame:CGRect(x:20, y:10, width: R, height: R))
        let _ = v.round()
        v.backgroundColor = Color.primary
        ImageLoader.shared.injectImage( from: user?.fetchThumbURL(), to: v ){ succ in return }
        
        if let alert = self.alert {
            v.alpha = alert.seen ? 0.50 : 1.0
        }

        
        // mount
        self.addSubview(v)
        self.img = v
        
        layoutName(for: R+10, btn: btn)

    }
    
    private func layoutName( for R: CGFloat, btn: Bool ){

        let f = self.frame
        let wd = f.width - R - 20 - 25 - 60
        
        let v = UITextView(frame: CGRect(x: R+20, y: 0, width: wd, height: f.height))
        v.font = UIFont(name: FontName.regular, size: AppFontSize.footer)
        if let alert = self.alert {
            v.textColor = alert.seen ? Color.grayPrimary : Color.primary_dark
        } else {
            v.textColor = Color.primary_dark
        }
        v.textAlignment = .left
        v.textContainer.lineBreakMode = .byWordWrapping
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        
        if let alert = self.alert {
            v.text = alert.text
        }
        
        addSubview(v)
        self.label = v
        
        if let alert = self.alert {
            if alert.kind == .inviteToGroup { //|| alert.kind == .taggedDeckAndInviteToGroup {
                if let grp = ClubList.shared.clubs[alert.meta] {
                    if let _ = grp.members[UserAuthed.shared.uuid] {
                    } else {
                        layoutBtn()
                    }
                } else {
                    layoutBtn()
                }
            } else {
                layoutBtn()
            }
        }
    }        
    
    private func layoutBtn(){
        
        btn?.removeFromSuperview()
        btn2?.removeFromSuperview()
        self.btn = nil
        self.btn2 = nil
        
        guard let alert = self.alert else { return }

        let f = self.frame
        let R = CGFloat(35.0)

        if alert.kind == .alertMe {

            let btn = TinderButton()
            btn.frame = CGRect(x: 0, y:10, width:R,height:R)
            btn.changeImage(to: "bell", scale: 1/2, color: Color.primary_dark)
            btn.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)
            btn.backgroundColor = Color.grayTertiary
            btn.center.x = f.width - 60/2 - 20
            if let img = self.img {
                btn.center.y = img.center.y
            }
            addSubview(btn)
            self.btn2 = btn
            
        } else {
            
            var str = ""
            switch alert.kind {
            case .follow:
                str = "Accept"
            case .alertMe:
                str = ""
            case .inviteToGroup:
                str = "Accept"
            case .joinGroup:
                str = ""
            default:
                str = ""
            }
            
            if str != "" {
                
                let c1 = alert.seen ? Color.grayPrimary : Color.primary_dark
                let c2 = Color.graySecondary
                
                let btn = TinderTextButton()
                btn.frame = CGRect(x: 0, y:10, width:55,height:R)
                btn.config(with: str, color: c1, font: UIFont(name: FontName.bold, size: AppFontSize.footerLight))
                btn.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)
                btn.backgroundColor = c2
                
                btn.center.x = f.width - 60/2 - 20
                if let img = self.img {
                    btn.center.y = img.center.y
                }
                addSubview(btn)
                self.btn = btn
            }
            
        }
    }
    
}


