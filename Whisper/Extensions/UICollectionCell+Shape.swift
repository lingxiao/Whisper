//
//  AppCollectionCell.swift
//  byte
//
//  Created by Xiao Ling on 5/25/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


extension UICollectionViewCell {

    func makeElipse() -> UICollectionViewCell {

        // border
        self.layer.borderWidth = 0.5
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.width*0.2
        self.clipsToBounds = true
        //self.contentMode = .scaleAspectFill
        
        return self
    }

    func border( width: CGFloat, color: CGColor ) -> UICollectionViewCell{
        self.layer.borderWidth = width
        self.layer.borderColor = color
        return self
    }

    //ㄥ(⸝ ، ⸍ )‾‾‾‾‾
    func onFleek(on obj : Any, with fn: Selector ) -> UICollectionViewCell {
        let singleTap = UITapGestureRecognizer(target: obj, action: fn)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(singleTap)
        return self

    }

}


extension UICollectionView {

    func scrollToNextItem() {
         let scrollOffset = CGFloat(floor(self.contentOffset.x + self.bounds.size.width))
         self.scrollToFrame(scrollOffset: scrollOffset)
    }

    func scrollToPreviousItem() {
        let scrollOffset = CGFloat(floor(self.contentOffset.x - self.bounds.size.width))
        self.scrollToFrame(scrollOffset: scrollOffset)
    }

    func scrollToFrame(scrollOffset : CGFloat) {
        guard scrollOffset <= self.contentSize.width - self.bounds.size.width else { return }
        guard scrollOffset >= 0 else { return }
        self.setContentOffset(CGPoint(x: scrollOffset, y: self.contentOffset.y), animated: true)
    }
}
