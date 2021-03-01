//
//  ResumeView.swift
//  byte
//
//  Created by Xiao Ling on 2/18/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

protocol ResumeViewDelegate {
    func onTapResumeView( from club: Club? ) -> Void
}

class ResumeView : UIView {
    
    var delegate: ResumeViewDelegate?
    var club: Club?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func onTap(){
        delegate?.onTapResumeView(from:self.club)
    }
    
    func config( with club: Club? ){
        
        self.club = club
        let _ = self.tappable(with: #selector(onTap))

        let _ = self.addBorder(width: 1.0, color: Color.graySecondary.cgColor)
        self.backgroundColor = UIColor.white
        
        let f = self.frame
        let R = f.height*2/3
        var dx = CGFloat(24)
        let dy = (f.height - R)/2
        
        let p = UIImageView(frame: CGRect(x: dx, y: dy, width: R, height: R))
        let _ = p.round()
        p.backgroundColor = Color.grayTertiary
        addSubview(p)

        let wR = R/4
        let frame = CGRect(x: (R-wR)/2, y: (R-wR)/2, width: wR, height: wR)
        let v = NVActivityIndicatorView(frame: frame, type: .lineScaleParty , color: Color.greenDark, padding: 0)
        p.addSubview(v)
        p.bringSubviewToFront(v)
        v.startAnimating()
        
        dx += R + 10
        
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect( x:dx, y: dy, width: f.width-dx-10, height: R/2)
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        h1.textAlignment = .left
        h1.verticalAlignment = .bottom
        h1.lineBreakMode = .byTruncatingTail
        h1.textColor = Color.primary_dark
        h1.text = club?.get_H1() ?? ""
        addSubview(h1)

        let h2 = VerticalAlignLabel()
        h2.frame = CGRect( x:dx, y: dy+R/2, width: f.width-dx-10, height: R/2)
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        h2.textAlignment = .left
        h2.verticalAlignment = .bottom
        h2.lineBreakMode = .byTruncatingTail
        h2.textColor = Color.primary_dark
        h2.text = club?.pp_attendingInRooms()
        addSubview(h2)
    }

}
