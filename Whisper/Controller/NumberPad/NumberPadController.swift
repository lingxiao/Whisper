//
//  NumberPadController.swift
//  byte
//
//  Created by Xiao Ling on 12/21/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import NVActivityIndicatorView


protocol NumberPadControllerDelegate {
    func onHandleHideNumberPad( with club: Club? ) -> Void
}

protocol NumberPadControllerDelegateOnboard {
    func onDidSyncWithSponsor(at code: String, with club: Club? ) -> Void
}

class NumberPadController : UIViewController {
    
    var delegate: NumberPadControllerDelegate?
    var onboardDelegate: NumberPadControllerDelegateOnboard?
    
    // data
    var number: String = ""
    var raw: String = ""
    var newClub: Club?

    // style
    var headerHeight: CGFloat = 70
    var statusHeight : CGFloat = 10.0
    var showHeader: Bool = true

    // view
    var header: AppHeader?
    var textInput: UILabel?
    var dotView: NVActivityIndicatorView?
    var room: RoomHeaderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureResponders()
        view.backgroundColor = Color.primary
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
    }

    public func config( with str: String = "Join private group", showHeader: Bool = true, isHome: Bool = false ){
        
        if showHeader {
            layoutHeader( str, isHome )
        }
        
        self.showHeader = showHeader
        layoutKeyPad( showHeader )
    }

}

//MARK:- btn responder

extension NumberPadController : AppHeaderDelegate {

    func onHandleDismiss() {
        self.delegate?.onHandleHideNumberPad( with: self.newClub )
    }
    
    @objc func handleBtn(_ button: TinderTextButton ){

        if raw.count == 10 {
            ToastSuccess(title: "", body: "Max 10 digits")
        } else {
            let r = button.code
            self.raw = "\(raw)\(r)"
            self.number = ppNumber()
            self.textInput?.text = self.number
        }
    }
    
    @objc func handleDelete(_ button: TinderButton ){
        removeRoom()
        let r = self.raw.dropLast()
        self.raw = String(r)
        self.number = ppNumber() == "(" ? "" : ppNumber()
        self.textInput?.text = self.number
    }
    
    @objc func handleSearch(_ button: TinderButton) {

        let code = self.raw

        if code.count != 10 {

            ToastSuccess(title: "", body: "Please enter 10 digit code")

        } else {

            placeIndicator( type: .ballBeat )

            UserAuthed.shared.syncWithNumber(at: code){ club in

                if let club = club {

                    // clear input field + show club
                    self.raw = ""
                    self.number = ""
                    self.textInput?.text = ""
                    self.layoutRoom(for: club)
                    self.newClub = club

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                        postRefreshNewsFeed()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                        postRefreshClubPage( at: club.uuid )
                        if let parent = self?.onboardDelegate {
                            parent.onDidSyncWithSponsor( at: code, with: club )
                        } else {
                            self?.removeIndicator()
                            ToastSuccess(title: "Synced with \(club.get_H1())", body: "Tap any active channel to chat with members.")
                            self?.onHandleDismiss()
                        }
                    }
                    
                } else {
                    ToastSuccess(title: "Oh no!", body: "We can't find an account matching this number, please try again")
                    self.removeIndicator()
                    self.raw = ""
                    self.number = ""
                    self.textInput?.text = ""
                }
            }
        }
    }
    
    private func ppNumber() -> String {
        var idx = 0
        var num = "("
        for c in self.raw {
            idx += 1
            if idx == 3 {
                num = "\(num)\(c)) "
            } else if idx == 6 {
                num = "\(num)\(c)-"
            } else {
                num = "\(num)\(c)"
            }
        }
        return num
    }
    
}


//MARK:- view

extension NumberPadController {

    func layoutHeader( _ str: String, _ isHome: Bool ){
        let f = view.frame
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        //header.config( showSideButtons: true, left: "", right: isHome ? "" : "xmark", title: str, mode: .light )
        header.config(showSideButtons: false, left: "", right: "", title: str, mode: .light, small: true)
        view.addSubview(header)
        header.backgroundColor = Color.primary
        header.delegate = self
        self.header = header
    }
    
    func layoutKeyPad( _ showHeader: Bool ){
           
        let f = view.frame
        var R = (f.height - headerHeight - statusHeight - 40 - 20 - 20 - 50 - 10)/5 - 10
        R = R > 90 ? CGFloat(90) : R

        // add number pad buttons
        var dy = showHeader ?  headerHeight + statusHeight + 40 : 40
        layoutText(dy: dy)
        dy += headerHeight + 50
        
        addRow(a: "1", b: "2", c: "3", dy: dy, R: R)
        dy += R + 20
        addRow(a: "4", b: "5", c: "6", dy: dy, R: R)
        dy += R + 20
        addRow(a: "7", b: "8", c: "9", dy: dy, R: R)
        dy += R + 20
        addRow(a: "", b: "0", c: "", dy: dy, R: R, addRmv: true)
        dy += R + 20
        
    }
    
    private func layoutText( dy: CGFloat ){
        let f = self.view.frame
        let v = UILabel(frame: CGRect(x: 20, y: dy, width: f.width-40, height: headerHeight))
        v.font = UIFont(name: FontName.bold, size: AppFontSize.H2)!
        v.textColor = Color.secondary_dark
        v.textAlignment = .center
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        v.text = self.number
        self.textInput = v
        view.addSubview(v)
    }
    
   private func addRow( a: String, b: String, c: String, dy: CGFloat, R: CGFloat, addRmv: Bool = false ){

        let f = view.frame
        var dx = (f.width - (  R + 20 + R + 20 + R )) / 2
        let odx = dx

        let r = R*0.30
        let font = UIFont(name: FontName.bold, size: r)!

        let one = TinderTextButton()
        one.code = a
        one.frame = CGRect(x: dx, y: dy, width: R, height: R)
        one.config(with: a, color: Color.secondary_dark, font: font)
        one.backgroundColor = Color.grayTertiary
        one.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)

        if a != "" {
            view.addSubview(one)
        }
        
        dx += R + 20

        let two = TinderTextButton()
        two.code = b
        two.frame = CGRect(x: dx, y: dy, width: R, height: R)
        two.config(with: b, color: Color.secondary_dark, font: font)
        two.backgroundColor = Color.grayTertiary
        two.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)

        if b != "" {
            view.addSubview(two)
        }
        
        dx += R + 20
        
        let three = TinderTextButton()
        three.code = c
        three.frame = CGRect(x: dx, y: dy, width: R, height: R)
        three.config(with: c, color: Color.secondary_dark, font: font)
        three.backgroundColor = Color.grayTertiary
        three.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)

        if c != "" {
            view.addSubview(three)
        }
        
        if addRmv {

            let r = R/2
            let rmv = TinderTextButton()
            rmv.frame = CGRect(x: odx, y: dy+r/2, width: R, height: r)
            rmv.config(with: "Delete", color: Color.redDark, font: UIFont(name: FontName.bold, size: AppFontSize.body2))
            rmv.backgroundColor = UIColor.clear
            view.addSubview(rmv)
            rmv.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
            
            let go = TinderTextButton()
            go.frame = CGRect(x: dx, y: dy+r/2, width: R, height: r)
            go.config(with: "Join", color: Color.secondary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.body2))
            go.backgroundColor = UIColor.clear
            view.addSubview(go)
            go.addTarget(self, action: #selector(handleSearch), for: .touchUpInside)

        }
    }
    
    private func layoutRoom( for club: Club? ){

        guard let club = club else { return }
        let f = self.view.frame
        let dy = self.showHeader ?  headerHeight + statusHeight + 40 : 40
        let v = RoomHeaderView(frame: CGRect(x: 20, y: dy, width: f.width-40, height: headerHeight+10))
        v.config(with: club )
        v.alpha = 0.0
        self.room = v
        view.addSubview(v)
        view.bringSubviewToFront(v)
        if let dv = self.dotView {
            view.bringSubviewToFront(dv)
        }

        func fn(){ v.alpha = 1.0 }
        runAnimation( with: fn, for: 0.25 ){}
    }
    
    private func removeRoom(){
        func fn(){ self.room?.alpha = 0.0 }
        runAnimation( with: fn, for: 0.25 ){
            self.room?.removeFromSuperview()
            self.room = nil
        }
    }

    
    private func placeIndicator( type: NVActivityIndicatorType ){
        let f  = view.frame
        let R  = CGFloat(30)
        let dx = f.width - 40 - R
        let dy = (self.showHeader ?  headerHeight + statusHeight + 40 : 40) + (headerHeight-R)/2
        let frame = CGRect( x: dx, y: dy, width: R, height: R )
        let v = NVActivityIndicatorView(frame: frame, type: .ballTrianglePath , color: Color.grayPrimary, padding: 0)
        self.view.addSubview(v)
        self.view.bringSubviewToFront(v)
        v.startAnimating()
        self.dotView = v
    }
    
    private func removeIndicator(){
        self.dotView?.removeFromSuperview()
        self.dotView = nil
    }

    
}

//MARK:- gesture

extension NumberPadController {
    
    func addGestureResponders(){
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .right
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                self.delegate?.onHandleHideNumberPad( with: self.newClub )
            case .down:
                break;
            case .left:
                self.delegate?.onHandleHideNumberPad( with: self.newClub )
            case .up:
                break;
            default:
                break
            }
        }
    }

    
}

