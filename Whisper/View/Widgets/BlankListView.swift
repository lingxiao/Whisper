//
//  BlankListView.swift
//  byte
//
//  Created by Xiao Ling on 10/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

class BlankListView: UIView {

    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // config
    func config( header: String, msg: String = "" ){

        self.backgroundColor = Color.primary
        
        let f = self.frame
        
        if header != "" {
            let title : UILabel = UILabel()
            let ht = CGFloat(100)
            title.frame = CGRect(x: 0, y: 5, width: f.width, height: ht )
            title.textAlignment = .center
            title.bodyBold()
            title.text = header
            addSubview(title)
        }
 
        let label : UILabel = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: f.width, height: AppFontSize.bodyBold+10)
        label.textAlignment = .center
        label.bodyBold()
        label.textColor = Color.primary_dark
        label.text = msg
        label.center = self.center

        addSubview(label)
    }
    
}
