//
//  ChatButton.swift
//  byte
//
//  Created by Xiao Ling on 2/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

enum ChatButtonState {
    case dormant
    case typing
    case unread
    case read
}

protocol ChatButtonDelegate {
    func didTap( on btn: ChatButton ) -> Void
}

class ChatButton : UIView {
    
    private var b1: TinderButton?
    private var b2: NVActivityIndicatorView?
    private var b3: TinderButton?
    private var isTyping : Bool = false

    var delegate: ChatButtonDelegate?
    var state: ChatButtonState = .dormant {
        didSet {
            respoondToChange()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func handleTapChat(_ button: TinderButton ){
        delegate?.didTap(on: self)
    }
    
    func config( with st: ChatButtonState ){
        let f = self.frame
        let R = f.width
        let btn = TinderButton()
        btn.frame = CGRect(x:0, y:0, width:R,height:R)
        btn.changeImage(to: "bubble-fill", alpha: 1.0, scale: 0.40, color: Color.greenDark)
        btn.backgroundColor = Color.grayTertiary
        btn.addTarget(self, action: #selector(handleTapChat), for: .touchUpInside)
        addSubview(btn)
        self.b1 = btn

        self.backgroundColor = Color.grayTertiary
        self.state = st
    }
    
    private func respoondToChange(){
        switch state {
        case .dormant:
            self.isTyping = false
            readMessage()
        case .typing:
            typing()
        case .unread:
            self.isTyping = false
            doneTypingWithMessage()
        case .read:
            self.isTyping = false
            doneTypingWithNoMessage()
        }
    }
    
    private func typing(){
        
        if self.isTyping { return }
        self.isTyping = true
        
        b2?.stopAnimating()
        b2?.removeFromSuperview()
        self.b2 = nil

        let f = self.frame
        let r = f.width/2
        let frame = CGRect(x: (f.width-r)/2, y: (f.height-r)/2, width: r, height: r)
        let v = NVActivityIndicatorView(frame: frame, type: .ballBeat , color: Color.greenDark, padding: 0)
        v.alpha = 0.0
        self.addSubview(v)
        self.bringSubviewToFront(v)
        self.b2 = v

        func fn(){
            self.b1?.alpha = 0.0
            self.b2?.alpha = 1.0
            self.b3?.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.10 ){
            self.b2?.startAnimating()
            self.b3?.removeFromSuperview()
        }
    }
    
    private func doneTypingWithNoMessage(){
        func fn(){
            self.b1?.alpha = 1.0
            self.b2?.alpha = 0.0
            self.b3?.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.10 ){
            self.b2?.stopAnimating()
            self.b2?.removeFromSuperview()
            self.b2 = nil
            self.b3?.removeFromSuperview()
            self.b3 = nil
        }
    }
    
    private func doneTypingWithMessage(){
        
        self.b3?.removeFromSuperview()

        let f = self.frame
        let R = f.width
        let btn = TinderButton()
        btn.frame = CGRect(x:0, y:0, width:R,height:R)
        btn.changeImage( to: "bubble-dots", color:Color.white )
        btn.backgroundColor = Color.purpleLite
        btn.alpha = 0.0
        btn.addTarget(self, action: #selector(handleTapChat), for: .touchUpInside)
        addSubview(btn)
        bringSubviewToFront(btn)
        self.b3 = btn
        
        func fn(){
            self.b1?.alpha = 0.0
            self.b2?.alpha = 0.0
            self.b3?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.10 ){
            self.b2?.stopAnimating()
            self.b2?.removeFromSuperview()
            self.b2 = nil
        }
    }
    
    private func readMessage(){
        func fn(){
            self.b1?.alpha = 1.0
            self.b2?.alpha = 0.0
            self.b3?.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.10 ){
            self.b2?.stopAnimating()
            self.b2?.removeFromSuperview()
            self.b2 = nil
            self.b3?.removeFromSuperview()
            self.b3 = nil
        }
    }
}
