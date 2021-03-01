//
//  InputStringModal.swift
//  byte
//
//  Created by Xiao Ling on 12/24/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


protocol InputStringModalDelegate {
    func handleInputString( _ str: String ) -> Void
}

class InputStringModal: UIView {
    
    // data
    var delegate: InputStringModalDelegate?
    var h1 : String = ""
    var h2 : String = ""
    
    //style + view
    var width: CGFloat = 0
    var input: UITextField?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        var dy: CGFloat = 20
        dy += AppFontSize.H1 + 20
        dy += AppFontSize.H1 + 10
        dy += AppFontSize.footer*2 + 20
        dy += 40 + 10
        return dy
    }
    
    func config( width: CGFloat, h1: String, h2: String ){
        self.width  = width
        self.h1     = h1
        self.h2     = h2
        layout()
    }
    
    @objc func handleBtn(_ button: TinderButton ){
        input?.resignFirstResponder()
        guard let raw = input?.text else { return }
        delegate?.handleInputString(raw)
    }
    
    private func layout(){
    
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  InputStringModal.height()))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.white
        addSubview(parent)
    
        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = UIColor.clear
        parent.addSubview(v)
        
        // title
        let h0 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H1))
        h0.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h0.text = self.h1
        h0.textColor = Color.primary_dark
        h0.textAlignment = .center
        h0.textContainer.lineBreakMode = .byWordWrapping
        h0.backgroundColor = UIColor.clear
        h0.isUserInteractionEnabled = false
        parent.addSubview(h0)
        
        dy += AppFontSize.H1 + 20
        
        // add input
        let rect =  CGRect(x: 0, y: dy, width: width, height: AppFontSize.H1)
        let ft = UIFont(name: FontName.bold, size: AppFontSize.H3)!
        let h1 = appTextField(placeholder: "", font: ft, frame: rect, color: Color.primary_dark  )
        h1.attributedPlaceholder = NSAttributedString(
              string: "Type here"
            , attributes: [NSAttributedString.Key.foregroundColor: Color.grayQuaternary
        ])
        h1.textAlignment = .center
        h1.textColor = Color.primary_dark
        h1.isUserInteractionEnabled = true
        parent.addSubview(h1)
        self.input = h1
        
        dy += AppFontSize.H1 + 10
        
        // add explain
        let h2 = UITextView(frame:CGRect(x:20,y:dy,width:width-40, height:AppFontSize.footer*2))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.text = self.h2
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = UIColor.clear
        h2.isUserInteractionEnabled = false
        parent.addSubview(h2)
        dy += AppFontSize.footer*2 + 20

        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn.config(with: "Save", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footer))
        btn.backgroundColor = Color.graySecondary
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBtn)))

        dy += 50 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = UIColor.clear
        parent.addSubview(vb)
        
        self.input?.becomeFirstResponder()
    }

}


