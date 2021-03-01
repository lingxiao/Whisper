//
//  HomeFooter.swift
//  byte
//
//  Created by Xiao Ling on 1/28/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit

protocol HomeFooterDelegate {
    func onTapProfile() -> Void
    func onTapAlerts()  -> Void
    func onTapNew()     -> Void
    func onTapHome()    -> Void
}

private let colorOn  = Color.black
private let colorOff = Color.grayPrimary.darker(by: 25)

class HomeFooter : UIView {
    
    var delegate: HomeFooterDelegate?
    
    // view
    var home: TinderButton?
    var bell: TinderButton?
    var pad : TinderButton?
    var prof: TinderButton?
    
    // scroll state
    var prevHt: CGFloat = 0
    var lastOpen: Int = now()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with color: UIColor ){
        layout(color)
        listenFreshAlerts(on: self, for: #selector(didGetNewAlerts))
        backgroundColor = color
    }
    
    @objc func onHome(_ button: TinderButton ){
        delegate?.onTapHome()
        home?.changeImage(to: "house", color:colorOn)
        bell?.changeImage(to: "bell-outline", color:colorOff)
        pad?.changeImage( to: "pad", color:colorOff)
        prof?.changeImage( to: "profile", color: colorOff)
    }

    @objc func onBell(_ button: TinderButton ){
        delegate?.onTapAlerts()
        home?.changeImage(to: "house", color:colorOff)
        bell?.changeImage(to: "bell-outline", color:colorOn)
        pad?.changeImage( to: "pad", color:colorOff)
        prof?.changeImage( to: "profile", color: colorOff)
    }
    
    @objc func onPad(_ button: TinderButton ){
        delegate?.onTapNew()
        home?.changeImage(to: "house", color:colorOff)
        bell?.changeImage(to: "bell-outline", color:colorOff)
        pad?.changeImage( to: "pad", color:colorOn)
        prof?.changeImage( to: "profile", color: colorOff)
    }

    
    @objc func onProfile(_ button: TinderButton ){
        delegate?.onTapProfile()
        home?.changeImage(to: "house", color:colorOff)
        bell?.changeImage(to: "bell-outline", color:colorOff)
        pad?.changeImage( to: "pad", color:colorOff)
        prof?.changeImage( to: "profile", color: colorOn)
    }

   
    public func maybeRemoveAlertDot(){
        if UserAuthed.shared.fetchUnseenAlerts().count > 0 { return }
        bell?.changeImage(to: "bell-outline", color:colorOff)
    }

    
    @objc func didGetNewAlerts(_ notification: NSNotification){
        addAlertDot()
    }

    public func addAlertDot(){
        bell?.changeImage(to: "bell-outline-dark", color:Color.redDark)
    }


    /*
     @use: place image,text, and two pills
    */
    private func layout( _ color: UIColor ){
        
        let _ = self.addBorder(width: 2.0, color: Color.graySecondary.cgColor)

        let f = self.frame
        let R = CGFloat(45)
        let dy = CGFloat(2)
        var dx  = CGFloat(40)
        let pad = (f.width - 2*dx - 4*R)/3
        
        // home
        let home = TinderButton()
        home.frame = CGRect(x:dx,y:dy, width:R, height:R)
        home.changeImage(to: "house", color:colorOn)
        home.backgroundColor = UIColor.clear
        home.addTarget(self, action: #selector(onHome), for: .touchUpInside)
        addSubview(home)
        self.home = home

        dx += R + pad
        
        // add alert
        let bell = TinderButton()
        bell.frame = CGRect(x:dx,y:dy, width:R, height:R)
        bell.changeImage(to: "bell-outline", color:colorOff)
        bell.backgroundColor = UIColor.clear
        bell.addTarget(self, action: #selector(onBell), for: .touchUpInside)
        addSubview(bell)
        self.bell = bell
        
        dx += R + pad
        
        // add number
        let btn = TinderButton()
        btn.frame = CGRect(x:dx,y:dy, width:R, height:R)
        btn.changeImage( to: "pad", color:colorOff)
        btn.backgroundColor = UIColor.clear
        btn.addTarget(self, action: #selector(onPad), for: .touchUpInside)
        addSubview(btn)
        self.pad = btn

        dx += R + pad

        // profile
        let prof = TinderButton()
        prof.frame = CGRect(x:dx,y:dy, width:R, height:R)
        prof.changeImage( to: "profile", color: colorOff)
        prof.backgroundColor = UIColor.clear
        prof.addTarget(self, action: #selector(onProfile), for: .touchUpInside)
        addSubview(prof)
        self.prof = prof
    }
    
    
    
}





