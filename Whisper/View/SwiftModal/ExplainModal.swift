//
//  ExplainModal.swift
//  byte
//
//  Created by Xiao Ling on 12/24/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


protocol ExplainModalDelegate {
    func handleConsent( from domain: Int ) -> Void
}

class ExplainModal: UIView {
    
    // data
    var delegate: ExplainModalDelegate?
    var h1 : String = ""
    var h2 : String = ""
    var h3 : String = "Ok"
    var domain: Int = 0
    
    //style
    var width: CGFloat = 0
    

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height( width: CGFloat, str: String ) -> CGFloat {
        var dy: CGFloat = 10
        dy += AppFontSize.H1 + 10
        let ( n , ht ) = computeLabelHt(width: width-20, str: str)
        dy += n > 3 ? ht + 40 : ht + 20
        dy += 40
        dy += 20
        return dy
    }
    
    func config( width: CGFloat, h1: String, h2: String, h3: String, domain: Int ){
        self.width  = width
        self.h1     = h1
        self.h2     = h2
        self.h3     = h3
        self.domain = domain
        layout()
    }
    
    @objc func handleBtn(_ button: TinderButton ){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 ) { [weak self] in
            guard let self = self else { return }
            self.delegate?.handleConsent( from: self.domain )
        }
    }
    
    
    private func layout(){
        
        let Ht = ExplainModal.height(width: self.width, str: self.h2)
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height: Ht))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)
        
        // title
        let h0 = UITextView(frame:CGRect(x:10,y:dy,width:width-20, height:AppFontSize.H1))
        h0.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h0.text = self.h1
        h0.textColor = Color.primary_dark
        h0.textAlignment = .left
        h0.textContainer.lineBreakMode = .byWordWrapping
        h0.backgroundColor = Color.primary
        h0.isUserInteractionEnabled = false
        parent.addSubview(h0)
        
        dy += AppFontSize.H1 + 10
        
        // add explain
        let h2 = UITextView(frame:CGRect(x:10,y:dy,width:width-20, height:AppFontSize.footerBold))
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h2.text = self.h2
        h2.textColor = Color.secondary_dark
        h2.textAlignment = .left
        h2.backgroundColor = Color.primary
        h2.isUserInteractionEnabled = false
        h2.sizeToFit()
        parent.addSubview(h2)

        let ( n , ht ) = computeLabelHt(width: width-20, str: self.h2)
        dy += n > 3 ? ht + 40 : ht + 20
        
        print( n , ht )

        // add button
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (width-width/2)/2, y:dy,width:width/2,height:40)
        btn.config(with: self.h3)
        btn.backgroundColor = Color.secondary_dark
        btn.textLabel?.textColor = Color.primary
        btn.textLabel?.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        parent.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBtn)))

        dy += 40
        
        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
    }


}


private func computeLabelHt(  width: CGFloat, str: String ) -> (Int,CGFloat) {
    
    if str == "" {
        return (1,2.0)
    } else {
        let v  = UILabel(frame: CGRect(x:20,y:0, width:width, height:0))
        v.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        v.text = str
        v.textAlignment = .left
        let maxNum = v.maxNumberOfLines
        return ( maxNum, v.requiredHeight )
//                 maxNum == 1
//                    ? 2*v.requiredHeight
//                    : maxNum < 5
//                    ? v.requiredHeight + AppFontSize.footerBold
//                    : v.requiredHeight - 1.5*AppFontSize.footerBold
    }
}
