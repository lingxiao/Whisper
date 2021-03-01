//
//  ConfirmTag.swift
//  byte
//
//  Created by Xiao Ling on 1/6/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


//MARK:- protocol + constants

protocol ConfirmTagDelegate {
    func onConfirmTag() -> Void
    func onConfirmTagAndInvite() -> Void
    func onDismissConfirmTag() -> Void
}

//MARK:- class

class ConfirmTag: UIView {
    
    var deck: FlashCardDeck?
    var club: Club?

    var headerHeight: CGFloat = 30
    var delegate: ConfirmTagDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    static func height() -> CGFloat {

        let headerHeight: CGFloat = 40
        let ht = AppFontSize.body + 30
        let ht2 = AppFontSize.footer * 3 + 20

        var dy = CGFloat(20)
        dy += headerHeight + 10
        dy += ht
        dy += ht2
        dy += 35
        dy += 10
        return dy
    }
    
    
    func config( with deck: FlashCardDeck?, on club: Club? ) {
        self.deck = deck
        self.club = club
        primaryGradient(on:self)
        addGestureResponders()
        layout()
    }
    
    
    @objc func onConfirmTag(sender : UITapGestureRecognizer){
        delegate?.onConfirmTag()
    }
   
    
    @objc func onConfirmTagAndInvite(sender : UITapGestureRecognizer){
        delegate?.onConfirmTagAndInvite()
    }
   
    
    private func layout(){
            
        let f = self.frame
        var dy = CGFloat(20)
        let ht = AppFontSize.body + 20
        let ht2 = AppFontSize.footer * 3 + 20
        let R  = ht/2
        let wd = (f.width-50-20)/2

        let header = AppHeader(frame: CGRect(x:0,y:dy,width:f.width,height:headerHeight))
        header.delegate = self
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Grow your cohort", mode: .light, small: true )
        addSubview(header)
        header.backgroundColor = UIColor.clear
        
        dy += headerHeight + 10
        
        // add user
        let name = deck?.creator?.get_H1()
        let icon = UIImageView(frame:  CGRect(x:20, y: dy+R/2 , width: R, height:R))
        let _ = icon.round()
        ImageLoader.shared.injectImage(from: deck?.creator?.fetchThumbURL(), to: icon){ _ in return }
        addSubview(icon)
        let h2 = UILabel(frame: CGRect(x: 15 + R + 10, y: dy, width: f.width-15-R-30, height: ht))
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        h2.lineBreakMode = .byTruncatingTail
        h2.text = name !=  nil ? "Started by \(name!)" : ""
        h2.backgroundColor = UIColor.clear
        h2.textColor = Color.primary_dark
        h2.textAlignment = .left
        addSubview(h2)
        
        dy += ht

        // add text
        let h3 = UITextView(frame: CGRect(x: 20, y: dy, width: f.width-15-R-5, height: ht2))
        h3.font = UIFont(name: FontName.regular, size: AppFontSize.footer)
        h3.textContainer.lineBreakMode = .byWordWrapping
        h3.text = "If you like this collection, you can invite \(name != nil ? name! : "the curator") to join your cohort."
        h3.backgroundColor = UIColor.clear
        h3.isUserInteractionEnabled = false
        h3.sizeToFit()
        h3.textColor = Color.primary_dark
        h3.textAlignment = .left
        addSubview(h3)

        dy += ht2
        
        // add btns
        let btn = TinderTextButton()
        btn.frame = CGRect(x: 25+wd+20, y: dy, width: wd, height: 35)
        btn.config(with: "Tag and invite", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn.backgroundColor = Color.white
        addSubview(btn)
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: 20, y: dy, width: wd, height: 35)
        btn2.config(with: "Just tag", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn2.backgroundColor = Color.white
        addSubview(btn2)

        btn.addTarget(self, action: #selector(onConfirmTagAndInvite), for: .touchUpInside)
        btn2.addTarget(self, action: #selector(onConfirmTag), for: .touchUpInside)
    }
    
}


//MARK:- gesture

extension ConfirmTag : AppHeaderDelegate {

    func onHandleDismiss() {
        delegate?.onDismissConfirmTag()
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
                delegate?.onDismissConfirmTag()
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

