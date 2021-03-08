//
//  NewRoomModal.swift
//  Whisper
//
//  Created by Xiao Ling on 3/8/21.
//


import Foundation
import UIKit
import SwiftEntryKit


protocol NewRoomModalDelegate {
    func onCancel() -> Void
    func onMkOpen() -> Void
    func onMkOneTime() -> Void
}

class NewRoomModal: UIView {
    
    // data
    var club : Club?
    var delegate: NewRoomModalDelegate?
    
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
        dy += 40 + 10
        dy += 20
        return dy
    }
    
    func config( width: CGFloat ){
        self.width = width
        layout()
    }
    
    
    @objc func onPerm(_ button: TinderButton ){
        delegate?.onMkOpen()
    }

    @objc func onCancel(_ button: TinderButton ){
        delegate?.onCancel()
    }

    @objc func onOnetime(_ button: TinderButton ){
        delegate?.onMkOneTime()
    }

    
    private func layout(){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  SwitchRoomModal.height()))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)

        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        h1.text = "Start a new room"
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 20
        
        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: 20, y:dy,width:width-40,height:40)
        btn.config(with:"Create permanen roomt")
        btn.backgroundColor = Color.graySecondary
        btn.textLabel?.textColor = Color.primary_dark
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onPerm)))

        dy += 40 + 10
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: 20, y:dy,width:width-40,height:40)
        btn2.config(with:"Create ephemeral room")
        btn2.backgroundColor = Color.graySecondary
        btn2.textLabel?.textColor = Color.primary_dark
        btn2.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn2)
        btn2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOnetime)))

        dy += 40 + 10
        
        let btn3 = TinderTextButton()
        btn3.frame = CGRect(x: 20, y:dy,width:width-40,height:40)
        btn3.config(with: "cancel")
        btn3.backgroundColor = Color.graySecondary
        btn3.textLabel?.textColor = Color.primary_dark
        btn3.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn3)
        btn3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCancel)))

        dy += 40 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }

}

