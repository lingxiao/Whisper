//
//  AwaitWidget.swift
//  byte
//
//  Created by Xiao Ling on 1/20/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


class AwaitWidget : UIView {
    
    private var dotView: NVActivityIndicatorView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func config( R: CGFloat = 100, with str: String = "loading" ){
        
        self.backgroundColor = Color.graySecondary.lighter(by: 25)
        
        let pf  = self.frame
        let tht = AppFontSize.footer + 5
        
        // indicator view
        let frame = CGRect( x: (pf.width-R/2)/2, y: (pf.height-R/2)/2, width: R/2, height: R/2 )
        let v = NVActivityIndicatorView(frame: frame, type: .ballBeat , color: Color.grayPrimary, padding: 0)
        addSubview(v)
        bringSubviewToFront(v)
        self.dotView = v
        
        // label view
        let h1 = UILabel(frame: CGRect(x: 0, y: pf.height-tht-5, width: pf.width, height: tht))
        h1.textAlignment = .center
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        h1.textColor = Color.grayPrimary
        h1.text = str
        addSubview(h1)
        
        // animate the dot
        v.startAnimating()
    }
    
    func stop(){
        dotView?.removeFromSuperview()
    }
}
