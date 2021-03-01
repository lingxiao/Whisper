//
//  RequestNumberModal.swift
//  byte
//
//  Created by Xiao Ling on 12/20/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit

protocol RequestNumberDelegate {
    func onHandleNewNumber() -> Void
}

class RequestNumberModal: UIView {
    
    // data
    var club : Club?
    
    //style
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    var delegate: RequestNumberDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        var dy: CGFloat = 20
        dy += AppFontSize.H1 + 20
        dy += AppFontSize.H2 + 5
        dy += AppFontSize.H2 + 20
        dy += 40 + 10
        return dy
    }
    
    func config( with club: Club?, width: CGFloat ){
        self.club   = club
        self.width  = width
        if let club = club { layout(club) }
    }
    
    
    @objc func handleBtn(_ button: TinderButton ){
        SwiftEntryKit.dismiss()
        delegate?.onHandleNewNumber()
    }
    
    private func layout( _ club: Club ){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height:  RequestNumberModal.height()))
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
        h1.text = "Request new number"
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 10
        
        // add explain
        let h2 = UITextView(frame:CGRect(x:20,y:dy,width:width-40, height:AppFontSize.H2))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.text = "This change is irreversible"
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = Color.primary
        h2.isUserInteractionEnabled = false
        parent.addSubview(h2)
        
        dy += AppFontSize.H2 + 5
        
        let h3 = UITextView(frame:CGRect(x:20,y:dy,width:width-40, height:AppFontSize.H2))
        h3.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h3.text = "Press change to continue"
        h3.textColor = Color.grayPrimary
        h3.textAlignment = .center
        h3.textContainer.lineBreakMode = .byWordWrapping
        h3.backgroundColor = Color.primary
        h3.isUserInteractionEnabled = false
        parent.addSubview(h3)
        
        dy += AppFontSize.H2 + 20

        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:50)
        btn.config(with: "Change")
        btn.backgroundColor = Color.secondary_dark
        btn.textLabel?.textColor = Color.primary
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBtn)))

        dy += 50 + 10
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }

}
