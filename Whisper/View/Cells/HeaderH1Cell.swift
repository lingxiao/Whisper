//
//  HeaderH1Cell.swift
//  byte
//
//  Created by Xiao Ling on 5/25/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



class HeaderH1Cell: UITableViewCell {
    
    static let identifier = "HeaderH1Cell"

    var label: VerticalAlignLabel?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label?.removeFromSuperview()
    }
    
    func config(
          with text : String?
        , color: UIColor = Color.primary
        , textColor: UIColor = Color.primary_dark
        , font: UIFont = UIFont(name: FontName.bold, size: AppFontSize.body)!
        , action: String? = nil
    ){
        
        let f = self.frame
        let v =  VerticalAlignLabel(frame:CGRect(x:20,y:0,width:f.width-40,height:f.height)) 
        v.font = font
        v.text = text ?? ""
        v.textColor = textColor
        v.textAlignment = .left
        v.verticalAlignment = .bottom
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        self.addSubview(v)
        self.label = v
        
    }
}


//MARK:- header 2

protocol HeaderH2CellDelegate {
    func didTapH2Btn() -> Void
}

class HeaderH2Cell: UITableViewCell {
    
    static let identifier = "HeaderH2Cell"

    var label: TinderTextButton?
    var delegate: HeaderH2CellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label?.removeFromSuperview()
    }
    
    @objc func didTap(_ button: TinderButton ){
        delegate?.didTapH2Btn()
    }

    
    func config(with text : String, font: UIFont = UIFont(name: FontName.bold, size: AppFontSize.footerLight)!){
        
        let f = self.frame
        let w = f.width/5
        let h = f.height-10
        let btn = TinderTextButton()
        btn.frame = CGRect(x: (f.width-w)/2, y: 5, width: w, height: h)
        btn.config(with: text, color: Color.primary_dark, font: font)
        btn.backgroundColor = Color.graySecondary
        addSubview(btn)
        self.addSubview(btn)
        self.label = btn
        btn.addTarget(self, action: #selector(didTap), for: .touchUpInside)

    }
}

//MARK:- header 3 -


class HeaderH3Cell: UITableViewCell {
    
    static let identifier = "HeaderH3Cell"

    var label: UITextView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label?.removeFromSuperview()
    }
    
    func config(
          with text : String?
        , color: UIColor = Color.primary
        , textColor: UIColor = Color.primary_dark
        , font: UIFont = UIFont(name: FontName.bold, size: AppFontSize.body)!
        , action: String? = nil
    ){
        
        let f = self.frame
        let v =  UITextView(frame:CGRect(x:20,y:0,width:f.width-40,height:f.height))
        v.font = font
        v.text = text ?? ""
        v.textColor = textColor
        v.textAlignment = .center
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        self.addSubview(v)
        self.label = v
        
    }
}
