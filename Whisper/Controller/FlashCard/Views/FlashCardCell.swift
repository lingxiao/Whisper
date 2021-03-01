//
//  FlashCardCell.swift
//  byte
//
//  Created by Xiao Ling on 1/1/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import Player
import NVActivityIndicatorView

//MARK:- delegate

protocol FlashCardCellDelegate {
    func onDelete( this card: FlashCardCell ) -> Void
    func onTapCardRight( from card: FlashCard? )  -> Void
    func onTapCardLeft ( from card: FlashCard? )  -> Void
    func onHandleTapProfile( from card: FlashCard? ) -> Void
    func didMute( from card: FlashCard? ) -> Void
    func didUnmute( from card: FlashCard? ) -> Void
    func didTapSeeAudience( from card: FlashCard? ) -> Void
}


//MARK:- view

class FlashCardCell: UIView {
    
    //static let identifier = "FlashCardCell"
    var delegate: FlashCardCellDelegate?
    
    // view
    var parent: UIView?
    var h1 : UITextView?
    var h1b: UITextView?
    var profile: UIImageView?
    var btn: TinderTextButton?
    var btns: [TinderButton] = []
    var backgroundImg: UIImageView?

    var player: Player?
    var muteBtn: TinderButton?
    var blurWidget: NVActivityIndicatorView?
    
    var card: FlashCard?
    var deck: FlashCardDeck?
    var frontVisible: Bool = true
    var showBtns: Bool = true
    
    var backShown: Bool = false
   
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK:- API
    
    func config( with card: FlashCard?, deck: FlashCardDeck?, showBtns: Bool = true ){
        
        let g = UITapGestureRecognizer(target: self, action:  #selector(didTap))
        self.addGestureRecognizer(g)
        self.card = card
        self.deck = deck
        self.showBtns = showBtns
        
        guard let card = card else { return }
            
        switch card.kind {
        case .image:
            layoutImage()
        case .video:
            layoutVideo()
        default:
            layoutText()
        }
    }
    
    func stopMedia(){
        player?.muted = true
        player?.stop()
    }
    
    public func setMute( muted : Bool ){
        if muted {
            muteBtn?.changeImage(to: "volume-off", scale: 1/2, color: Color.white)
            player?.muted = true
        } else {
            muteBtn?.changeImage(to: "volume-on", scale: 1/2, color: Color.white)
            player?.muted = false
        }
        muteBtn?.backgroundColor = Color.primary_transparent_A
    }
    
    //MARK:- events
    
    @objc func didTap(sender : UITapGestureRecognizer){

        let point = sender.location(in: self)
        let x = point.x
        let mid = self.frame.width/2

        if x > mid {
            delegate?.onTapCardRight(from: self.card)
        } else {
            delegate?.onTapCardLeft(from: self.card)
        }
        
        SwiftEntryKit.dismiss()
    }
    
    
    @objc func handleTapDefine(_ button: TinderButton ){

        if !backShown {

            self.backShown = true
            self.h1?.alpha  = 0.0
            self.h1b?.alpha = 1.0
            self.btn?.textLabel?.text = "SEE FRONT"
            self.parent?.backgroundColor = Color.blue1
            self.profile?.alpha = 0.0
            
            for btn in self.btns {
                btn.alpha = 0.0
            }
            
        } else {

            self.backShown = false
            self.h1?.alpha  = 1.0
            self.h1b?.alpha = 0.0
            self.btn?.textLabel?.text = "SEE BACK"
            self.parent?.backgroundColor = Color.tan
            self.profile?.alpha = 1.0
            
            for btn in self.btns {
                btn.alpha = 1.0
            }
        }
    }
    
    @objc func handleTapRemove(_ button: TinderButton ){
        SwiftEntryKit.dismiss()
        delegate?.onDelete(this:self)
    }
    
    @objc func onHandleTapProfile(sender : UITapGestureRecognizer){
        delegate?.onHandleTapProfile( from: self.card )
    }

    @objc func handleTapMute(_ button: TinderButton ){
        guard let player = player else { return }
        if player.muted {
            setMute(muted: false)
            delegate?.didUnmute(from: self.card)
        } else {
            setMute(muted: true)
            delegate?.didMute(from: self.card)
        }

    }
    
    @objc func handleTapReplay(sender : UITapGestureRecognizer){
        player?.playFromBeginning()
    }

    @objc func handleTapEye(sender : UITapGestureRecognizer){
        delegate?.didTapSeeAudience(from: self.card)
    }

    
    
    //MARK:- view
    
    private func layoutImage(){
        
        let pf = self.frame

        // image
        let v = UIImageView(frame:CGRect(x:5, y:0, width:pf.width-10, height:pf.height))
        let _ = v.corner(with: 15)
        v.backgroundColor = Color.primary_dark
        ImageLoader.shared.injectImage( from: card?.fetchThumbURL(), to: v ){ succ in return }
        v.isUserInteractionEnabled = true
        addSubview(v)
        self.backgroundImg = v
        
        layoutBtns()
        
    }

    private func layoutText(){
        
        guard let card = card else { return }

        let pf = self.frame
        let f = self.frame

        let parent = UIView(frame: CGRect(x: 5, y: 0, width: f.width-10, height: f.height))
        parent.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 15)
        parent.backgroundColor = Color.tan
        self.parent = parent
        addSubview(parent)

        let strs = card.front.components(separatedBy: " ")
        
        // front of card text
        let h1 = UITextView(frame: CGRect(x: 20, y: 0, width: pf.width-40, height: AppFontSize.H1+20))
        if showBtns {
            if strs.count > 4 {
                h1.textAlignment = .left
                h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
                h1.textContainer.lineBreakMode = .byWordWrapping
            } else {
                h1.textAlignment = .center
                h1.font = UIFont(name: FontName.bold, size: AppFontSize.H2)
                h1.textContainer.lineBreakMode = .byWordWrapping
            }
        } else {
            h1.textAlignment = .center
            h1.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
            h1.textContainer.lineBreakMode = .byTruncatingTail
        }
        h1.textColor = UIColor.black
        h1.backgroundColor = UIColor.clear
        h1.text = card.front
        h1.sizeToFit()
        h1.center.y = self.center.y

        addSubview(h1)
        h1.isUserInteractionEnabled = false
        self.h1 = h1
        
        //back of card text
        let h1b = UITextView(frame: CGRect(x: 0, y: 0, width: pf.width-20, height: AppFontSize.H1*2))
        h1b.textAlignment = strs.count > 4 ? .left : .center
        h1b.font = UIFont(name: FontName.regular, size: AppFontSize.body)
        h1b.textColor = UIColor.black
        h1b.backgroundColor = UIColor.clear
        h1b.text = card.back
        h1b.textContainer.lineBreakMode = .byWordWrapping
        h1b.sizeToFit()
        h1b.alpha = 0.0
        h1b.center.y = self.center.y
        h1b.center.x = self.center.x - 10
        self.addSubview(h1b)
        h1b.isUserInteractionEnabled = false
        self.h1b = h1b

        let h = CGFloat(AppFontSize.H3+20)
        let w  =  (f.width-20)/2
        let dy = f.height - h - 10

        // meta btn
        if self.showBtns && card.back != "" {
            let b3 = TinderTextButton()
            b3.frame = CGRect(x:(f.width-w)/2,y:dy,width:w,height:h)
            b3.config(with: "SEE BACK", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerLight))
            b3.backgroundColor = UIColor.clear
            b3.addTarget(self, action: #selector(handleTapDefine), for: .touchUpInside)
            addSubview(b3)
            self.btn = b3
                    
            layoutBtns()

        }        
    }
    
    private func layoutVideo(){
        
        let pf = self.frame

        let player = Player()
        player.playerDelegate = self
        player.playbackDelegate = self
        player.muted = true
        player.view.frame = CGRect(x: 5, y: 0, width: pf.width-10, height: pf.height)
        player.view.backgroundColor = Color.black.lighter(by: 10)
        player.fillMode = .resizeAspectFill
        let _ = player.view.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 15)

        addSubview(player.view)
        self.player = player
        
        self.addBlur()
        self.layoutBtns(muted: true)
        
        card?.awaitMedia(){ url in
            self.player?.url = url
            self.player?.playFromBeginning()
        }
    }
        
    private func layoutBtns( muted: Bool = true ){

        self.muteBtn?.removeFromSuperview()
        for btn in btns {
            btn.removeFromSuperview()
        }
        self.btns = []
        
        if self.showBtns == false { return }
        guard let card = card else { return }
                
        let f = frame
        let R = CGFloat(30)
        let pad = CGFloat(15)
        var dy = f.height - R - 24
        let dx = f.width-R-20
        
        // rmv btn
        if let deck = self.deck {
            if deck.isMine() || card.isMine() {
                let rmv = TinderButton()
                rmv.frame = CGRect(x: 20, y: dy, width: R, height: R)
                rmv.changeImage(to: "dots", alpha: 1.0, scale: 1/3, color: card.kind == .text ? Color.primary_dark : Color.white)
                rmv.backgroundColor = UIColor.clear
                rmv.addTarget(self, action: #selector(handleTapRemove), for: .touchUpInside)
                addSubview(rmv)
                self.btns.append(rmv)
            }
        }
        
        // invite to cohort btn
        
        
        // profile btn
        let v = UIImageView(frame: CGRect(x: dx, y: dy, width: R, height: R))
        let _ = v.round()
        let _ = v.border(width: 1.0, color: Color.primary_transparent_B.cgColor)
        v.backgroundColor = Color.primary_transparent_B
        ImageLoader.shared.injectImage( from: card.creator?.fetchThumbURL(), to: v ){ succ in return }
        v.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapProfile))
        v.addGestureRecognizer(gesture)
        addSubview(v)
        self.profile = v

        dy -= (R + pad)
        
        // num views btn
        let eye = TinderButton()
        eye.frame = CGRect(x: dx, y: dy, width: R, height: R)
        if card.kind == .text {
            eye.changeImage(to: "eye", alpha: 1.0, scale: 0.60, color: Color.primary_dark)
            eye.backgroundColor = Color.grayQuaternary
        } else {
            eye.changeImage(to: "eye", alpha: 1.0, scale: 0.60, color: Color.white)
            eye.backgroundColor = Color.primary_transparent_A
        }
        eye.addTarget(self, action: #selector(handleTapEye), for: .touchUpInside)
        addSubview(eye)
        self.btns.append(eye)

        dy -= (R + pad)

        // video playback btn
        if card.kind == .video {

            let replay = TinderButton()
            replay.frame = CGRect(x: dx, y: dy, width: R, height: R)
            replay.changeImage(to: "sync", alpha: 1.0, scale: 0.60, color: Color.white)
            replay.backgroundColor = Color.primary_transparent_A
            replay.addTarget(self, action: #selector(handleTapReplay), for: .touchUpInside)
            addSubview(replay)
            self.btns.append(replay)

            dy -= (R + pad)

            let mute = TinderButton()
            mute.frame = CGRect(x:dx, y:dy, width:R,height:R)
            if muted {
                mute.changeImage(to: "volume-off", scale: 1/2, color: Color.white)
            } else {
                mute.changeImage(to: "volume-on", scale: 1/2, color: Color.white)
            }
            mute.backgroundColor = Color.primary_transparent_A
            mute.addTarget(self, action: #selector(handleTapMute), for: .touchUpInside)
            addSubview(mute)
            self.muteBtn = mute
            self.btns.append(mute)
        }


    }
        
    
    private func addBlur(){
        
        removeBlur()
        
        let R = CGFloat(30)
        let frame = CGRect( x: 0, y: 0, width: R, height: R )
        let widget = NVActivityIndicatorView(frame: frame, type: .circleStrokeSpin , color: Color.white, padding: 0)
        addSubview(widget)
        bringSubviewToFront(widget)
        widget.center = self.center
        widget.startAnimating()
        self.blurWidget = widget
    }
        
    private func removeBlur(){
        if let v = self.blurWidget {
            v.stopAnimating()
            v.removeFromSuperview()
            self.blurWidget = nil
        }
    }
}



//MARK:- Player delegate

extension FlashCardCell: PlayerPlaybackDelegate {

    func playerCurrentTimeDidChange(_ player: Player) {
        return
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
        removeBlur()
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
        player.playFromBeginning()
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
        return
    }
    
    func playerPlaybackDidLoop(_ player: Player) {
        return
    }
    
}

extension FlashCardCell: PlayerDelegate {

    func playerReady(_ player: Player) {
        return
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        return
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        return
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
        return
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        if let e = error?.localizedDescription as? String {
            ToastSuccess(title: "Oh no!", body: e)
        }
    }
}


/*
 private func layoutUserProfle( light: Bool ){
     
     guard let user = card?.creator else { return }
     
     let f = self.frame
     
     let h = CGFloat(AppFontSize.H3+20)

     let v = UIImageView(frame:CGRect(x:20, y:20+h/4, width: h/2, height: h/2))
     let _ = v.round()
     v.backgroundColor = Color.grayTertiary
     ImageLoader.shared.injectImage( from: user.fetchThumbURL(), to: v ){ succ in return }
     v.isUserInteractionEnabled = true
     let gesture = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapProfile))
     v.addGestureRecognizer(gesture)
     addSubview(v)
     self.bubble = v
         
     if !light {
         let h2 = UITextView(frame: CGRect(x: 20+h/2+5, y: 20, width: f.width/2, height: AppFontSize.footerLight+20))
         h2.textAlignment = .left
         h2.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
         h2.textColor = light ? Color.white : Color.grayPrimary
         h2.backgroundColor = UIColor.clear
         h2.text = "Added by \(user.get_H1())"
         h2.textContainer.lineBreakMode = .byTruncatingTail
         h2.isUserInteractionEnabled = false
         addSubview(h2)
         h2.center.y = v.center.y
         self.h2 = h2
     }
 }
 

 private func layoutDeleteBtn(){
     
     guard let card = card else { return }

     // del btn
     var canDel : Bool = false
     if let deck = self.deck {
         canDel = deck.isMine()
     }
     
     let f = self.frame
     let h = CGFloat(AppFontSize.H3+20)

     if card.isMine() || canDel {
         let b4 = TinderButton()
         b4.frame = CGRect(x:f.width-20-h,y:20,width:h,height:h)
         b4.changeImage(to: "minus", alpha: 1.0, scale: 0.30, color: Color.grayPrimary)
         b4.backgroundColor = UIColor.clear
         b4.addTarget(self, action: #selector(handleTapRemove), for: .touchUpInside)
         addSubview(b4)
         self.btn2 = b4
     }
     
 }
 

 */
