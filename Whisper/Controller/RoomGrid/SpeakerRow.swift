//
//  SpeakerRow.swift
//  byte
//
//  Created by Xiao Ling on 12/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import PopBounceButton
import Combine
import UIKit.UIImage
import NVActivityIndicatorView


protocol SpeakerRowDelegate {
    func onTapSpeakerRowUser( at user: User? ) -> Void
}

class SpeakerRow: UITableViewCell, SpeakerRowDelegate {
    
    // storyboard identifier
    static let identifier = "SpeakerRow"
    var delegate: SpeakerRowDelegate?
    var room: Room?
    
    // views
    var cells: [AudioCell] = []    
    
    override func prepareForReuse(){
        super.prepareForReuse()
        for c in cells {
            c.removeFromSuperview()
        }
        self.cells = []
    }
    
    //MARK:- API
    
    static func height( num: Int ) -> CGFloat {
        let f = UIScreen.main.bounds
        let R = f.width/CGFloat(num)
        return R
    }
    
    func config( with users: [RoomMember], at room: Room? ){
        
        if users.count == 0  { return }
        guard let room = room else { return }
            
        let f = self.frame
        self.backgroundColor = Color.primary
        self.room = room
        
        var dx  : CGFloat = 10
        let num : CGFloat = room.isRoot ? 4 : 3
        let pad : CGFloat = room.isRoot ? 10 : 20
        let R   : CGFloat = ((f.width - 2*pad) - pad * (num-1))/num
        
        for mem in users {
            let v = AudioCell(frame: CGRect(x:dx,y:0,width:R,height:R))
            v.config(user: mem.user, roomID: self.room?.uuid)
            if mem.muted {
                v.setMute(to: true)
            }
            v.delegate = self
            addSubview(v)
            self.cells.append(v)
            dx += R + pad
        }
    }
    
    
    func onTapSpeakerRowUser(at user: User?){
        delegate?.onTapSpeakerRowUser(at: user)
    }

}



//MARK:- cell

class AudioCell: UIView {
    
    var delegate : SpeakerRowDelegate?

    private var img: UIImageView?
    private var txt: UILabel?
    private var mute: UIImageView?
    private var ho: UILabel?
     
    var user: User?
    var roomID: String = ""
    var speaking: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
        
    func config( user: User?, roomID: String? ){
        
        self.user  = user
        self.roomID = roomID ?? ""
            
        let f = self.frame
        let R = f.height - AppFontSize.footerLight-10
            
        // profile img
        let img  = UIImageView()
        img.frame = CGRect(x:(f.width-R)/2,y:8,width:R,height:R)
        let _ = img.round()
        let _ = img.addBorder(width: 2.0, color: Color.redLite.cgColor)
        img.backgroundColor = Color.grayQuaternary
        addSubview(img)
        self.img = img
        
        // add txt
        let h1 = UILabel()
        h1.frame = CGRect( x:10, y: R+10, width: f.width-20, height: AppFontSize.footerLight+10)
        h1.font = UIFont(name: FontName.regular, size: AppFontSize.footerLight)
        h1.textAlignment = .center
        h1.textColor = Color.primary_dark
        self.addSubview(h1)
        self.txt = h1

        if GLOBAL_DEMO && GLOBAL_SHOW_DEMO_PROFILE {
            let (rand_name,rand_img) = fromTwentyMember(at:user) // getRandomUserValuesFromDummyUser(at:user)
            let pic = UIImage(named: rand_img)
            img.image = pic
            h1.text = rand_name
        } else {
            
            var char: String = "A"
            if let user = user {
                h1.text = user.isMe() ? "You" : user.get_H1()
                char = String(user.get_H1().prefix(1))
            }
                
            // then fill in image if it exists
            DispatchQueue.main.async {
                if let url = user?.fetchThumbURL() {
                    ImageLoader.shared.injectImage(from: url, to: img){ _ in return }
                } else {
                    let sz = R*0.30
                    let ho = UILabel(frame: CGRect(x: (f.width-sz)/2-10, y: (f.height-sz)/2-10, width: sz, height: sz))
                    ho.font = UIFont(name: FontName.bold, size: sz)
                    ho.textAlignment = .center
                    ho.textColor = Color.grayQuaternary.darker(by: 50)
                    ho.text = char.uppercased()
                    self.ho = ho
                    img.addSubview(ho)
                }
            }
        }
        
        // add responder
        img.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        img.addGestureRecognizer(tap)
       
        // listen for mute
        listenForDidMute(on: self, for: #selector(didMute))
        listenForDidUnMute(on: self, for: #selector(didUnMute))
            
        // listen for speaking vs not
        listenForDidSpeaking(on:self, for: #selector(isSpeaking))
        listenForDidUnSpeaking(on:self, for: #selector(notSpeaking))

    }

    // respond w/ visiual queue, bubble event
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        func fn(){ self.img?.alpha = 0.75 }
        func gn(){ self.img?.alpha = 1.00 }
        runAnimation( with: fn, for: 0.10 ){
            runAnimation( with: gn, for: 0.10 ){ return }
            self.delegate?.onTapSpeakerRowUser( at: self.user )
        }
    }

    
    @objc func didMute(_ notification: NSNotification){
        if isForMe(notification){
            setMute(to: true)
        }
    }
    
    @objc func didUnMute(_ notification: NSNotification){
        if isForMe(notification){
            setMute(to: false)
        }
    }
    
    @objc func isSpeaking(_ notification: NSNotification){
        if isForMe(notification){
            setSpeaking(to: true)
        }
    }
    
    @objc func notSpeaking(_ notification: NSNotification){
        if isForMe(notification){
            setSpeaking(to: false)
        }
    }
    
    // @use: add mute
    func setMute( to muted: Bool ){
        if muted {
            if let mt = self.mute {
                bringSubviewToFront(mt)
                mt.alpha = 1.0
            } else {
                let f = self.frame
                let R = f.height - AppFontSize.footerLight-10
                let r = R/4
                let raw = UIImageView(image: UIImage(named: "mic-off"))
                let img = raw.colored( Color.primary_dark )
                img.frame = CGRect(x:R-3,y:R-8, width: r,  height: r)
                self.addSubview(img)
                self.mute = img
                self.bringSubviewToFront(img)
            }
        } else {
            self.mute?.alpha = 0.0
        }
    }
    
    // @use: when speakikng, show ring
    func setSpeaking( to yes : Bool ){

        if yes && !self.speaking {
            
            self.speaking = true
            let _ = img?.addBorder(width: 2.0, color: Color.redDark.cgColor )

        } else if !yes && self.speaking {
                        
            self.speaking = false
            let _ = img?.addBorder(width: 2.0, color: Color.redLite.cgColor )

        }

    }
    
   
    private func isForMe(_ notification: NSNotification) -> Bool {
        guard let user = user else { return false }
        guard let uid = decodePayloadForField(field: "userID", notification) else { return false }
        guard let rid = decodePayloadForField(field: "roomID", notification) else { return false }
        return user.uuid == uid && roomID == rid
    }
    
    
}

