//
//  UIButton+Style.swift
//  byte
//
//  Created by Xiao Ling on 7/6/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- these functions style the buttons. they do not attach them
// to the view, neither do they attach function listners

extension UIButton {
    
    func label ( _ xs: String ) -> UIButton {
        self.setTitle(xs, for: .normal)
        self.setTitleColor( UIColor.black, for: .normal )
        self.titleLabel?.font =  UIFont(name: FontName.bold, size: AppFontSize.body)
        return self
    }
    
    func font( name: String, size: CGFloat ) -> UIButton {
        self.titleLabel?.font =  UIFont(name: name, size: size)
        return self
    }
    
    func dim( x: Int, y: Int, wd: Int, ht: Int) -> UIButton {
        self.frame = CGRect(
              x: x
            , y: y
            , width: wd
            , height: ht
        )
        return self
    }
    
    func rounded() -> UIButton {
        self.layer.cornerRadius = 20
        self.layer.borderWidth  = 0.5
        self.layer.borderColor  = Color.secondary.cgColor
        self.backgroundColor = UIColor.white
        self.tintColor = UIColor.black
        return self
    }
    
    func circle() -> UIButton{
        self.layer.cornerRadius = self.frame.width/2
        self.layer.borderWidth  = 0.5
        self.layer.borderColor  = Color.primary.cgColor
        self.backgroundColor = Color.primary
        self.tintColor = Color.primary
        return self
    }
    
    func border( color: CGColor, width: CGFloat ) -> UIButton {
        self.layer.borderWidth  = width
        self.layer.borderColor  = color
        return self
    }
    
    func paint( with val : UIColor ) -> UIButton {
        self.backgroundColor = val
        return self
    }
    
}
