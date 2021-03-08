//
//  PhoneNumberView.swift
//  byte
//
//  Created by Xiao Ling on 1/8/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


//MARK:- protocol + constants

protocol PhoneNumberViewDelegate {
    func onDismissPhoneNumberView() -> Void
}  

private let TEXT : String = "Share this number with prospective members so they can access this space. If you believe your number has been compromised, you can request a new number by tapping the scramble button. Existing members can still access the space, but prospective users can no longer access this channel with your old number."

private let ALT_TEXT : String = "Share this number with prospective members so they can access this space."


//MARK:- class

class PhoneNumberView: UIView {

    // data
    var club: Club?
    var short: Bool = false
    
    var headerHeight: CGFloat = 40
    var textHt: CGFloat = 40
    var h1: UITextView?
    var h2: UITextView?
    
    var delegate: PhoneNumberViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    static func Height( with club: Club?, width: CGFloat, short: Bool) -> CGFloat {
        
        var str = ALT_TEXT
        if let club = club {
            str = !short && club.iamOwner ? TEXT : ALT_TEXT
        }
        
        var dy : CGFloat = 5
        let ht = PhoneNumberView.TextHeight(width: width, str: str)
        dy += 40
        dy += AppFontSize.H2 + 20
        dy += ht + 20
        dy += 35
        dy += 20
        return dy
    }
    
    static func TextHeight( width: CGFloat, str: String ) -> CGFloat {
        // compute dynamic height
        let h2 = UITextView()
        h2.frame = CGRect(x: 0, y: 0, width: width, height: AppFontSize.footer)
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.textColor = Color.secondary.darker(by: 50)
        h2.backgroundColor = UIColor.clear
        h2.text = str
        return h2.sizeThatFits(h2.bounds.size).height
    }

    func config( with club: Club?, short: Bool = false ){
        self.club = club
        self.short = short
        primaryGradient(on:self)
        layout(short: short)
        addGestureResponders()
    }
    
    @objc func handleMix(_ button: TinderButton ){
        guard let club = club else {
            delegate?.onDismissPhoneNumberView()
            return
        }
        guard let org = ClubList.shared.fetchOrg(for:club) else {
            delegate?.onDismissPhoneNumberView()
            return
        }
        if club.iamOwner && !self.short {
            org.scrambleBackdoorCode(){ code in
                self.h1?.text = org.getPhoneNumber(front:false)
            }
        } else {
            delegate?.onDismissPhoneNumberView()
        }
    }
    
    @objc func handleShare(_ button: TinderButton ){
        guard let club = club else { return }
        guard let org = ClubList.shared.fetchOrg(for:club) else { return }
        let code = org.getPhoneNumber(front:false)
        guard let url = UserAuthed.shared.getInstallURL() else { return }
        let suffix = "My number is \(code), find me on \(APP_NAME): \(url)."
        let sms: String = "sms:&body=\(suffix)"
        if let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)
        } else {
            heavyImpact()
            ToastSuccess(title: "", body: "You cannot invite guests yet")
        }
    }
    
    private func layout(short:Bool){

        let f = frame
        var dy : CGFloat = 5
        let wd = (f.width - 40 - 15)/2
        
        var str = "Ok"
        var txt = ALT_TEXT
        if let club = self.club {
            if club.iamOwner && !short {
                str = "Scramble"
                txt = TEXT
            }
        }
        
        let ht : CGFloat = PhoneNumberView.TextHeight(width: f.width, str: txt)

        // header
        let header = AppHeader(frame: CGRect(x:5,y:dy, width:f.width-10,height:headerHeight))
        header.delegate = self
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Share invite code", mode: .light, small: true )
        header.label?.textColor = Color.primary_dark
        addSubview(header)
        header.backgroundColor = UIColor.clear

        dy += headerHeight
        
        // phone number
        let h1 = UITextView(frame:CGRect(x:20,y:dy,width:f.width-40,height:AppFontSize.H2+20))
        h1.textAlignment = .center
        h1.backgroundColor = UIColor.clear
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H2)
        h1.text = ClubList.shared.fetchOrg(for:club)?.getPhoneNumber(front:false) ?? ""
        h1.textColor = Color.secondary_dark
        h1.textContainer.lineBreakMode = .byTruncatingTail
        h1.isUserInteractionEnabled = false
        addSubview(h1)
        self.h1 = h1
        
        dy += AppFontSize.H2 + 20
        
        // explain
        let h2 = UITextView(frame:CGRect(x:20,y:dy,width:f.width-40,height:ht))
        h2.textAlignment = .left
        h2.backgroundColor = UIColor.clear
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.text = txt
        h2.textColor = Color.primary_dark.lighter(by: 10)
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.isUserInteractionEnabled = false
        h2.sizeToFit()
        addSubview(h2)
        
        dy += ht + 20
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: 20, y: dy, width: wd, height: 35)
        btn2.config(with: str, color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn2.backgroundColor = Color.white
        addSubview(btn2)
        btn2.addTarget(self, action: #selector(handleMix), for: .touchUpInside)
        btn2.center.x = self.center.x
    }



}



extension PhoneNumberView  : AppHeaderDelegate {

    func onHandleDismiss(){
        delegate?.onDismissPhoneNumberView()
    }
    
    func addGestureResponders(){
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .down
        self.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                break;
            case .down:
                delegate?.onDismissPhoneNumberView()
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

