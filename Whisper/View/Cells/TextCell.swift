//
//  TextCell.swift
//  byte
//
//  Created by Xiao Ling on 11/19/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



class TextCell: UITableViewCell {
    
    static let identifier = "TextCell"

    var label: UITextView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label?.removeFromSuperview()
    }
    
    static func Height( for str: String, width: CGFloat, font: UIFont? ) -> CGFloat {
        let h2 = UITextView()
        h2.frame = CGRect(x: 0, y: 0, width: width, height: AppFontSize.H2)
        h2.font = font ?? UIFont(name: FontName.regular, size: AppFontSize.body2)
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.textColor = Color.primary
        h2.text = str
        let contentSize = h2.sizeThatFits(h2.bounds.size)        
        return contentSize.height
    }
   
    
    func config(
          with str: String
        , textColor: UIColor = Color.primary_dark
        , font: UIFont = UIFont(name: FontName.regular, size: AppFontSize.body2)!
        , textAlignment : NSTextAlignment = .left
    ){
        
        let f = self.frame
        let v = UITextView(frame:CGRect(x:20,y:0,width:f.width-40,height:f.height))
        v.font = font
        v.text = str
        v.textColor = textColor
        v.textAlignment = textAlignment
        v.textContainer.lineBreakMode = .byWordWrapping
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        self.addSubview(v)
        self.label = v
    }
        
}
