//
//  HeroCell.swift
//  byte
//
//  Created by Xiao Ling on 12/7/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


/*
 @Use: user profile pic and name 
*/
class HeroCell: UITableViewCell {

    // storyboard identifier
    static let identifier = "HeroCell"
    
    // data
    var user: User?
    
    // view + style
    var nameFont: UIFont?
    var img: UIImageView?
    var label: VerticalAlignedLabel?
    
    override func prepareForReuse(){
        super.prepareForReuse()
        img?.removeFromSuperview()
        label?.removeFromSuperview()
    }
    
    func config( with user: User?, nameFont: UIFont? ){
        self.user = user
        self.nameFont = nameFont
        layoutImage()

    }
    
    private func layoutImage(){
        
        let f = self.frame
        let R = f.height - AppFontSize.H1 - 30

        let v = UIImageView(frame:CGRect(x:0, y:0, width: R, height: R))
        let _ = v.round()
        v.backgroundColor = Color.grayQuaternary
        
        if let url = user?.fetchThumbURL() {
            
            ImageLoader.shared.injectImage( from: url, to: v ){ succ in return }

        } else {
            
            var char = "A"
            
            if let str = user?.get_H1() {
                char = String(str.prefix(1))
            }
            
            let sz = R/3
            let ho = UILabel(frame: CGRect(x:0, y:0, width: sz, height: sz))
            ho.font = UIFont(name: FontName.bold, size: sz)
            ho.textAlignment = .center
            ho.textColor = Color.grayQuaternary.darker(by: 50)
            ho.text = char.uppercased()
            ho.center = v.center
            v.addSubview(ho)
        }
        
        // mount
        v.center.x = self.center.x
        self.addSubview(v)
        self.img = v
        
        layoutName(for: R)

    }
    
    private func layoutName( for R: CGFloat ){

        let f = self.frame
        let ht = f.height - R - 10
        
        let label : VerticalAlignedLabel = VerticalAlignedLabel()
        label.frame = CGRect(x: 0, y: R+10, width: f.width, height: ht)
        label.textAlignment = .center
        label.font = self.nameFont ?? UIFont(name: FontName.icon, size: AppFontSize.H1)
        label.textColor = Color.secondary_dark
        
        if let user = self.user {
            label.text = user.get_H1()
        }

        addSubview(label)
        self.label = label
    }

}
