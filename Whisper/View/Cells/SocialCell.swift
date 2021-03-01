//
//  SocialCell.swift
//  byte
//
//  Created by Xiao Ling on 12/8/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol SocialCellProtocol {
    func follow()   -> Void
    func ig()       -> Void
    func twitter()  -> Void
    func linkedin() -> Void
    func onBell()   -> Void
    func onDots()   -> Void
}

/*
 @Use: follow + social media
*/
class SocialCell: UITableViewCell {

    // storyboard identifier
    static let identifier = "SocialCell"
    
    // data
    var user: User?
    var delegate : SocialCellProtocol?
    
    // view + style
    var follow: TinderTextButton?
    var ig: TinderButton?
    var linkedin: TinderButton?
    var twitter: TinderButton?
    var dots: TinderButton?
    var bell: TinderButton?

    override func prepareForReuse(){
        super.prepareForReuse()
        follow?.removeFromSuperview()
        linkedin?.removeFromSuperview()
        twitter?.removeFromSuperview()
        ig?.removeFromSuperview()
        dots?.removeFromSuperview()
        bell?.removeFromSuperview()
    }
    
    func config( with user: User?, nameFont: UIFont? ){

        self.user = user
        layoutSocial(ht:10)
        
        // listen to event
        listenForDidFollow(on: self, for: #selector(didFollow))
        listenForDidUnFollow(on: self, for: #selector(didUnFollow))
        listenIdidBlock(on:self, for: #selector(didBlockOrUnBlock))
    }
    
    //MARK:- events

    @objc func handleFollow(_ button: TinderButton ){
        delegate?.follow()
    }


    @objc func handleIg(_ button: TinderButton ){
        delegate?.ig()
    }

    
    @objc func handleTwitter(_ button: TinderButton ){
        delegate?.twitter()
    }

    
    @objc func handleLinkedin(_ button: TinderButton ){
        delegate?.linkedin()
    }
    
    @objc func handleDots(_ button: TinderButton ){
        delegate?.onDots()
    }
    
    @objc func handleBell(_ button: TinderButton ){
        delegate?.onBell()
    }
    
    //MARK:- events
    
    @objc func didFollow(_ notification: NSNotification){
        if isForMe(notification) == false { return }
        follow?.textLabel?.text = "Unfollow"
        follow?.backgroundColor = Color.grayTertiary
        follow?.textLabel?.textColor = Color.primary_dark
        if UserAuthed.shared.iAmFollowing(at: user?.uuid){
            bell?.changeImage( to: "bell-ring" )
        } else {
            bell?.changeImage( to: "bell" )
        }
    }

    @objc func didUnFollow(_ notification: NSNotification){
        if isForMe(notification) == false { return }
        follow?.textLabel?.text = "Follow"
        follow?.backgroundColor = Color.redDark
        follow?.textLabel?.textColor = Color.primary
    }
    
    @objc func didBlockOrUnBlock(_ notification: NSNotification){
        if WhisperGraph.shared.iDidBlock(this: user){
            dots?.changeImage( to: "shield" )
        } else {
            dots?.changeImage( to: "dots" )
        }
    }
    

    private func isForMe(_ notification: NSNotification) -> Bool {
        guard let user = user else { return false }
        guard let uid = decodePayloadForField(field: "userID", notification) else { return false }
        return user.uuid == uid
    }
    
    
    //MARK:- view

    func layoutSocial( ht: CGFloat ){
        
        let dy: CGFloat = 10
        let R : CGFloat = 50.0

        let tw = TinderButton()
        tw.frame = CGRect(x:0, y:dy, width:R,height:R)
        tw.changeImage( to: "twitter" )
        tw.addTarget(self, action: #selector(handleTwitter), for: .touchUpInside)
        tw.backgroundColor = Color.primary
        
        let ig = TinderButton()
        ig.frame = CGRect(x:0, y:dy, width:R,height:R)
        ig.changeImage( to: "instagram" )
        ig.addTarget(self, action: #selector(handleIg), for: .touchUpInside)
        ig.backgroundColor = Color.primary

        let li = TinderButton()
        li.frame = CGRect(x:0, y:dy, width:R,height:R)
        li.changeImage( to: "link-sq" )
        li.addTarget(self, action: #selector(handleLinkedin), for: .touchUpInside)
        li.backgroundColor = Color.primary

        var str = ""
        if let user = self.user {
            if user.isMe() {
                str = "vdots"
            } else {
                if WhisperGraph.shared.iDidBlock(this: user){
                    str = "shield"
                } else {
                    str = "dots"
                }
            }
        }
        
        let dots = TinderButton()
        dots.frame = CGRect(x:0, y:dy, width:R,height:R)
        dots.changeImage( to: str )
        dots.addTarget(self, action: #selector(handleDots), for: .touchUpInside)
        dots.backgroundColor = Color.primary

        let bell = TinderButton()
        bell.frame = CGRect(x:0, y:dy-2, width:R*1.1,height:R*1.1)
        
        if UserAuthed.shared.iAmFollowing(at: user?.uuid){
            bell.changeImage( to: "bell-ring" )
        } else {
            bell.changeImage( to: "bell" )
        }


        bell.addTarget(self, action: #selector(handleBell), for: .touchUpInside)
        bell.backgroundColor = Color.primary

        let cx = self.center.x
        /*ig.center.x = CX + 3 + R/2
        tw.center.x = CX - 3 - R/2
        dots.center.x = CX + R + 3 + R/2
        bell.center.x = CX - R - 3 - R/2*/
        
        tw.center.x = cx
        bell.center.x = cx - R - 3
        dots.center.x = cx + R + 3

        //ig.center.x = self.center.x
        //tw.center.x = center.x - R - 5
        //li.center.x = center.x + R + 5
        //dots.center.x = center.x + 2*R + 10
        //bell.center.x = center.x - 2*R - 10

        //addSubview(ig)
        addSubview(tw)
        //addSubview(li)
        addSubview(dots)
        addSubview(bell)
        
        self.ig       = ig
        self.twitter  = tw
        self.linkedin = li
        self.dots     = dots
        self.bell     = bell

    }

}
