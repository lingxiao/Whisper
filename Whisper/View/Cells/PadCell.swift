//
//  PadCell.swift
//  byte
//
//  Created by Xiao Ling on 5/25/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


/*
 @Use: add 25 px padding
*/
class PadCell: UITableViewCell {

    // storyboard identifier
    static let identifier = "PadCell"
    
    func config( color: UIColor = UIColor.clear){
        self.contentView.backgroundColor = color
    }
    
}



/*
 @Use: add 25 px padding
*/
class LineCell: UITableViewCell {

    // storyboard identifier
    static let identifier = "LineCell"
    
    var line: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.line?.removeFromSuperview()
    }
    
    func config( dx: CGFloat, color: UIColor = Color.grayQuaternary ){
        
        let f = self.frame
        let R = CGFloat(2)
        let v = UIView(frame: CGRect(x: dx, y: f.height-R, width: f.width-dx, height: R))
        v.backgroundColor = color
        v.roundCorners(corners: [.topLeft,.bottomLeft], radius: 1)
        addSubview(v)
        self.line = v
    }
    
}
