//
//  PictureRow.swift
//  byte
//
//  Created by Xiao Ling on 12/13/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



//MARK:- horizontal row of pics

class PictureRow : UIView {
    
    var imga: UIImageView?
    var imgB: UIImageView?
    var imgC: UIImageView?

    var data: [URL?] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with pics: [URL?], gap: CGFloat, numPics: Int ){

        self.data = pics

        if pics.count == 0 { return }
        let prefix = pics.prefix(numPics)
        
        var str = pics.count - numPics > 0 ? "\(pics.count - numPics) more" : ""
        
        if GLOBAL_DEMO {
            let n = Int.random(in: 0..<30)
            str = "\(n) more"
        }
        
        let f = self.frame
        var dx : CGFloat = 0
        let R  : CGFloat = f.height
        
        for url in prefix {
            let v = UIImageView(frame: CGRect(x:dx,y:(f.height-R)/2,width:R,height:R))
            let _ = v.round()
            v.backgroundColor = Color.grayTertiary
            let _ = v.border(width: 1.0, color: Color.white.cgColor)
            
            if GLOBAL_DEMO {
                let (_,_,rand_img) = getRandomUser()
                let pic = UIImage(named: rand_img)
                v.image = pic
            } else {
                ImageLoader.shared.injectImage(from: url, to: v, shouldFocusOnFace: false){ _ in return }
            }
            
            addSubview(v)
            dx += R - gap
        }
        
        dx += 10
        
        let v = VerticalAlignLabel(frame: CGRect(x: dx, y:0, width: f.width-dx, height: f.height))
        v.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        v.textColor = Color.grayPrimary.darker(by: 10)
        v.textAlignment = .left
        v.verticalAlignment = .middle
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        v.text = str
        addSubview(v)
    }


}


