//
//  ExitRoomModal.swift
//  byte
//
//  Created by Xiao Ling on 12/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


protocol ExitRoomModalDelegate {
    func onHandleExit() -> Void
    func onHandleShutdown() -> Void
}

class ExitRoomModal: UIView {
    
    // data
    var club : Club?
    var user : User?
    var delegate: ExitRoomModalDelegate?
    
    //style
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        var dy: CGFloat = 10
        dy += AppFontSize.H1 + 10
        dy += 40 + 10
        dy += 40 + 10
        dy += AppFontSize.H2 + 5
        dy += AppFontSize.H2 + 10
        dy += 20
        return dy
    }
    
    func config( width : CGFloat ){
        self.width  = width
        layout()
    }
    
    
    @objc func onShutDown(_ button: TinderButton ){
        delegate?.onHandleShutdown()
    }
    

    @objc func onExit(_ button: TinderButton ){
        delegate?.onHandleExit()
    }
    
    private func layout(){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  ExitRoomModal.height()))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)

        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = "Exit options"
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 20
        
        let h2 = UITextView(frame:CGRect(x:30,y:dy,width:width-60, height:AppFontSize.H2))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.text = "If you shut down the room, everyone will"
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = Color.primary
        h2.isUserInteractionEnabled = false
        parent.addSubview(h2)
        
        dy += AppFontSize.H2 + 5
        
        let h3 = UITextView(frame:CGRect(x:30,y:dy,width:width-60, height:AppFontSize.H2))
        h3.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h3.text = "be booted."
        h3.textColor = Color.grayPrimary
        h3.textAlignment = .center
        h3.textContainer.lineBreakMode = .byWordWrapping
        h3.backgroundColor = Color.primary
        h3.isUserInteractionEnabled = false
        parent.addSubview(h3)
        
        dy += AppFontSize.H2 + 20
        
        let wd = width*2/3
        let dx = (width - wd)/2
        
        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: dx, y:dy,width:wd,height:40)
        btn.config(with: "Shut down the room")
        btn.backgroundColor = Color.graySecondary
        btn.textLabel?.textColor = Color.primary_dark
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onShutDown)))

        dy += 40 + 10
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: dx, y:dy,width:wd,height:40)
        btn2.config(with: "Leave room", color: Color.primary, font: UIFont(name: FontName.bold, size: AppFontSize.footer))
        btn2.backgroundColor = Color.redDark
        parent.addSubview(btn2)
        btn2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onExit)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }

}
