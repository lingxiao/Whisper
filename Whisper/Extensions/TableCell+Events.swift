//
//  UITableViewCellExtension.swift
//  byte
//
//  Created by Xiao Ling on 5/24/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit




extension UITableViewCell {
  func separator(hide: Bool) {
    separatorInset.left += hide ? bounds.size.width : 0
  }
}



extension UITableViewCell{
    
    func doTap( on obj : Any, with fn: Selector ) -> UITableViewCell {
        let singleTap = UITapGestureRecognizer(target: obj, action: fn)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(singleTap)
        return self
    }

    /*
     @use: full proof way to highlight cell
     */
    func animateDark(from src: UIColor, to tgt: UIColor){
        UIView.animate(
              withDuration: 0.3
            , animations: {
                self.contentView.backgroundColor = tgt
            }
            , completion: { succ in
                self.animateBack(src)
            }
        )
    }
    
    private func animateBack(_ src: UIColor ){
        UIView.animate(withDuration: 0.3, animations: {
            self.contentView.backgroundColor = src
        })
    }
    
}

//extension UITableViewCell {
//
//    func doTap( with fn: Selector ) -> UITableViewCell {
//        let singleTap = UITapGestureRecognizer(target: self, action: fn)
//        self.isUserInteractionEnabled = true
//        self.addGestureRecognizer(singleTap)
//        return self
//    }
//}
