//
//  HomeHeader.swift
//  byte
//
//  Created by Xiao Ling on 12/17/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

protocol HomeHeaderDelegate {
    func onProfile() -> Void
    func onBell() -> Void
    func onNewGroup() -> Void
}

class HomeHeader : UIView {
    
    var delegate: HomeHeaderDelegate?
    
    // view
    var label: VerticalAlignLabel?
    var addBtn: TinderButton?
    var bell: TinderButton?

    var redDot: UIImageView?
    var addedRedDot: Bool = false
    
    // scroll state
    var prevHt: CGFloat = 0
    var lastOpen: Int = now()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( simple: Bool, title: String ){
        if simple{
            layoutSimple( with: title )
        } else {
            layout()
        }
    }
    
    func setLabel( to str: String ){
        if str == "" { return }
        self.label?.text = str
    }
    
    @objc func onBell(_ button: TinderButton ){
        delegate?.onBell()
    }
    
    @objc func onProfile(_ button: TinderButton ){
        delegate?.onProfile()
    }

    @objc func onGroup(_ button: TinderButton ){
        delegate?.onNewGroup()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        return
    }
    
    private func styleAdd( dark: Bool ){
        guard let btn = self.addBtn else { return }
        if dark {
            btn.backgroundColor = Color.secondary_dark
            btn.changeImage(to: "plus", scale: 1/2, color: Color.grayTertiary )
        } else {
            btn.backgroundColor = Color.graySecondary
            btn.changeImage(to: "plus", scale: 1/2, color: Color.primary_dark )
        }
    }
    
    /*
     @use: place title only
    */
    private func layoutSimple( with title: String ){

        let f = self.frame
        let R = CGFloat(40)
        let lwd = f.width - 2*20 - 2*R - 10 //- 2*R - 10 - 10
        
        // label
        let label = VerticalAlignLabel()
        label.frame = CGRect(x: 20, y: 0, width: lwd, height: AppFontSize.H1)
        label.textAlignment = .left
        label.verticalAlignment = .bottom
        label.textColor = Color.primary_dark.darker(by: 25)
        label.font = UIFont(name: FontName.icon, size: 30)
        label.text = title != "" ? "\(title)" : APP_NAME
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)
        label.center.y = f.height - R/2
        self.label = label
        
        let icon = TinderButton()
        icon.frame = CGRect(x:0,y:(f.height-R), width:R, height:R)
        icon.changeImage(to: "vdots", alpha: 1.0, scale: 0.40, color: Color.grayPrimary.darker(by: 50))
        icon.backgroundColor = Color.graySecondary
        icon.addTarget(self, action: #selector(onProfile), for: .touchUpInside)
        addSubview(icon)
        icon.center.x = f.width - 20 - R/2
        
        let icon2 = TinderButton()
        icon2.frame = CGRect(x:0,y:(f.height-R), width:R, height:R)
        icon2.changeImage(to: "plus", alpha: 1.0, scale: 0.40, color: Color.grayPrimary.darker(by: 50))
        icon2.backgroundColor = Color.graySecondary
        icon2.addTarget(self, action: #selector(onGroup), for: .touchUpInside)
        addSubview(icon2)
        icon2.center.x = f.width - 20 - R/2 - 5 - R
    }


    /*
     @use: place image,text, and two pills
    */
    private func layout(){

        let f = self.frame
        let R = CGFloat(40)
        let lwd = f.width - 2*R - 3*10 - 20
        
        // label
        let label = VerticalAlignLabel()
        label.frame = CGRect(x: 20, y: 0, width: lwd, height: AppFontSize.H1)
        label.textAlignment = .left
        label.verticalAlignment = .bottom
        label.textColor = Color.secondary_dark
        label.font = UIFont(name: FontName.icon, size: AppFontSize.H1)
        label.text = APP_NAME
        addSubview(label)
        label.center.y = f.height - R/2
        
        // add alert
        let bell = TinderButton()
        bell.frame = CGRect(x:0,y:(f.height-R), width:R, height:R)
        bell.changeImage( to: "bell" )
        bell.backgroundColor = Color.graySecondary
        bell.addTarget(self, action: #selector(onBell), for: .touchUpInside)
        addSubview(bell)
        self.bell = bell

        // add number
        let btn = TinderButton()
        btn.frame = CGRect(x:0,y:(f.height-R), width:R, height:R)
        btn.changeImage( to: "plus", scale: 1/2 )
        btn.backgroundColor = Color.graySecondary
        btn.addTarget(self, action: #selector(onGroup), for: .touchUpInside)
        addSubview(btn)
        self.addBtn = btn

        // profile
        let prof = TinderButton()
        prof.frame = CGRect(x:0,y:(f.height-R), width:R, height:R)
        prof.changeImage( to: "profile" )
        prof.backgroundColor = Color.graySecondary
        prof.addTarget(self, action: #selector(onProfile), for: .touchUpInside)
        addSubview(prof)

        prof.center.x = f.width - 20 - R/2
        btn.center.x  = f.width - 20 - R/2 - R - R - 10
        bell.center.x = f.width - 20 - R/2 - R - 5

    }
    
}
