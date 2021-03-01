//
//  UserRowCell.swift
//  byte
//
//  Created by Xiao Ling on 12/8/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol UserRowCellProtocol {
    func handleTap( on user: User? ) -> Void
    func handleBtn( on user: User? ) -> Void
}

class UserRowCell: UITableViewCell {
    
    static let identifier = "UserRowCell"
    var delegate : UserRowCellProtocol?

    // view
    var img: UIImageView?
    var btn: TinderTextButton?
    var label: VerticalAlignedLabel?
    var ho: UILabel?
    var bigFont: Bool = true

    // data
    var user: User?
    var hasBtn: Bool = false
    private var changing: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.btn?.removeFromSuperview()
        self.label?.removeFromSuperview()
        self.ho?.removeFromSuperview()
    }
    
    func config( with user: User?, button: Bool, bigFont: Bool = true ){

        self.user = user
        self.hasBtn = button
        self.bigFont = bigFont
        
        layoutImage( btn: button )
        self.selectionStyle = .none
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
        // listen to event
        listenForDidFollow(on: self, for: #selector(didFollow))
        listenForDidUnFollow(on: self, for: #selector(didUnFollow))
    }
    
    func highlight( _ b : Bool ){
        if b {
            img?.backgroundColor = Color.grayTertiary.darker(by: 10)
            label?.backgroundColor = Color.primary.darker(by: 10)
            self.backgroundColor = Color.primary.darker(by: 10)
        } else {
            img?.backgroundColor = Color.grayTertiary
            label?.backgroundColor = Color.primary
            self.backgroundColor = Color.primary
        }
    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.handleTap(on: user)
    }
    
    @objc func handleBtn(_ button: TinderButton ){
        if changing { return }
        delegate?.handleBtn(on: user)
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
        
        let f = self.frame
        let R = f.height - 20

        let v = UIImageView(frame:CGRect(x:20, y:(f.height-R)/2, width: R, height: R))
        let _ = v.round()
        v.backgroundColor = Color.grayQuaternary
        
        let (rand_name,rand_img) = getRandomUserValuesFromDummyUser(at: self.user)
        if GLOBAL_DEMO {
            let pic = UIImage(named: rand_img)
            v.image = pic
        } else {
            if let url = user?.fetchThumbURL() {
                DispatchQueue.main.async {
                    ImageLoader.shared.injectImage(from: url, to: v){ _ in return }
                }
            } else {
                var char : String = ""
                if let user = user {
                    char = String(user.get_H1().prefix(1))
                }

                let sz = R/3
                let ho = UILabel(frame: CGRect(x: (R-sz)/2, y: (R-sz)/2, width: sz, height: sz))
                ho.font = UIFont(name: FontName.bold, size: sz)
                ho.textAlignment = .center
                ho.textColor = Color.grayQuaternary.darker(by: 50)
                ho.text = char.uppercased()
                self.ho = ho
                v.addSubview(ho)
            }
        }
        
        // mount
        self.addSubview(v)
        self.img = v
        
        layoutName(for: R+10, btn: btn,name:rand_name)

    }
    
    private func layoutName( for R: CGFloat, btn: Bool, name: String ){

        let f = self.frame
        let wd = f.width - R - 20 - ( btn ? 60 : 0 )
        let dx = CGFloat(bigFont ? 20 : 15)
        
        let label : VerticalAlignedLabel = VerticalAlignedLabel()
        label.frame = CGRect(x: R+dx, y: 0, width: wd, height: f.height)
        label.textAlignment = .left
        label.font = self.bigFont
            ? UIFont(name: FontName.bold, size: AppFontSize.footerBold)
            : UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        label.textColor = Color.primary_dark
        label.backgroundColor = UIColor.clear
        
        if GLOBAL_DEMO {
            label.text = name
        } else {
            label.text = user?.get_H1() ?? ""
        }

        addSubview(label)
        self.label = label

    }
        
    
    private func layoutBtn(){
        
        if let b = self.btn {
            b.removeFromSuperview()
            self.btn = nil
        }

        let f = self.frame
        let R = f.height/2

        let btn = TinderTextButton()
        btn.frame = CGRect(x: 0, y:(f.height-R)/2,width:60,height:R)
        btn.config(with: "Follow")
        btn.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)
        
        btn.backgroundColor = Color.primary_dark
        btn.textLabel?.textColor = Color.primary
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        
        btn.center.x = f.width - 60/2 - 20
        addSubview(btn)
        self.btn = btn
    }
    
}
