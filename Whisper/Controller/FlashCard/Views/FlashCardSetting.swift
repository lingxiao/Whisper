//
//  FlashCardSetting.swift
//  byte
//
//  Created by Xiao Ling on 1/4/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


//MARK:- protocol + constants

protocol FlashCardSettingDelegate {
    func onDismissSettings    () -> Void
    func handleTapDeleteDeck  () -> Void
    func onHandleTapProfile   () -> Void
    func handleTapDeckPrivacy () -> Void
    func handleDeckTagged     () -> Void
}

//MARK:- class

class FlashCardSetting: UIView {
    
    var deck: FlashCardDeck?
    var club: Club?

    var headerHeight: CGFloat = 40

    
    var delegate: FlashCardSettingDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    static func height( for deck: FlashCardDeck?, club: Club? ) -> CGFloat {

        var dy = CGFloat(20)
        let headerHeight = CGFloat(40)
        let ht = AppFontSize.footerBold + 30
        dy += headerHeight + 10
        dy += ht
        dy += ht
        dy += ht

        if let mkr = deck?.creator {
            if mkr.isMe(){
                dy += ht
            }
        } else {
            dy += ht
        }
        dy += 20
        return dy
    }
    
    
    func config( with deck: FlashCardDeck?, on club: Club? ) {
        self.deck = deck
        self.club = club
        primaryGradient(on:self)
        addGestureResponders()
        layout()
    }
    
    @objc func onHandleTapProfile(sender : UITapGestureRecognizer){
        delegate?.onHandleTapProfile()
    }
   
    @objc func handleTapDeckPrivacy(sender : UITapGestureRecognizer){
        delegate?.handleTapDeckPrivacy()
    }
   
    @objc func handleTapDeleteDeck(sender : UITapGestureRecognizer){
        delegate?.handleTapDeleteDeck()
    }
   
    @objc func handleDeckTagged(sender : UITapGestureRecognizer){
        delegate?.handleDeckTagged()
    }
    
    private func layout(){
            
        let f = self.frame
        var dy = CGFloat(20)
        let ht = AppFontSize.footerBold + 30

        let header = AppHeader(frame: CGRect(x:0,y:dy,width:f.width,height:headerHeight))
        header.delegate = self
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Details", mode: .light )
        addSubview(header)
        header.backgroundColor = UIColor.clear
        
        dy += headerHeight + 10
        let name = deck?.creator?.get_H1() ?? ""
        let h1 = mkCell(icon: "profile", label: "Created by \(name)", dy: dy)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapProfile))
        h1.addGestureRecognizer(g1)

        dy += ht

        var icon = "locked"
        var str  = "This deck can only be edited by the creator"
        
        if let deck = deck {
            if deck.createdBy == UserAuthed.shared.uuid {
                str = "Tap to change privacy settings"
                icon = "unlock"
            } else if deck.iCanEdit() {
                str = "You can add to this collection"
                icon = "unlock"
            } else {
                str = "You cannot edit this collection"
                icon = "locked"
            }
        }
        
        let h2 = mkCell(icon: icon, label: str, dy: dy)
        let g2 = UITapGestureRecognizer(target: self, action:  #selector(handleTapDeckPrivacy))
        h2.addGestureRecognizer(g2)
        
        dy += ht
        let h3 = mkCell(icon: "bookmark", label: deck?.pp_num_tagged() ?? "", dy: dy)
        let g3 = UITapGestureRecognizer(target: self, action:  #selector(handleDeckTagged))
        h3.addGestureRecognizer(g3)
        
        dy += ht
        if let maker = deck?.creator {
            if maker.isMe(){
                let h4 = mkCell(icon: "xmark", label: "Delete collection", dy: dy)
                let g4 = UITapGestureRecognizer(target: self, action:  #selector(handleTapDeleteDeck))
                h4.addGestureRecognizer(g4)
            }
        }
    }
    
    private func mkCell( icon str: String, label strB: String, dy: CGFloat ) -> VerticalAlignLabel {

        let f    = self.frame
        let R    = AppFontSize.footerBold + 30
        
        let icon = TinderButton()
        icon.frame = CGRect(x:15, y: dy, width: R, height:R)
        icon.changeImage( to: str )
        icon.backgroundColor = UIColor.clear
        
        let h1 = VerticalAlignLabel(frame:CGRect(x: 25+R, y: dy, width: f.width-30-R-24, height: R))
        h1.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h1.textColor = Color.secondary_dark
        h1.textAlignment = .left
        h1.verticalAlignment = .middle
        h1.backgroundColor = UIColor.clear
        h1.isUserInteractionEnabled = true
        h1.text = strB
        
        addSubview(icon)
        addSubview(h1)
        
        return h1
    }
    
    
}


//MARK:- gesture

extension FlashCardSetting : AppHeaderDelegate {

    func onHandleDismiss() {
        delegate?.onDismissSettings()
    }
    

    func addGestureResponders(){
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .down
        addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                break;
            case .down:
                delegate?.onDismissSettings()
            case .left:
                break;
            case .up:
                break;
            default:
                break
            }
        }
    }
}

