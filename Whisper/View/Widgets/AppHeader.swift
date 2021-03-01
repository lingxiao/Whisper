//
//  AppHeader.swift
//  byte
//
//  Created by Xiao Ling on 7/16/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol AppHeaderDelegate {
    func onHandleDismiss() -> Void
}


class AppHeader : UIView {
    
    var delegate : AppHeaderDelegate?
    var mode: StyleMode = .dark
    var smallFont: Bool = false
    var label: VerticalAlignLabel?
    var label2: UILabel?
    
    // style
    var color: UIColor = Color.primary
    var accent: UIColor = Color.primary_dark
    
    var left: String  = ""
    var right: String = ""
    var title: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func onPressProfile(){
        return
    }

    @objc func onmatch(_ button: TinderButton ){
        delegate?.onHandleDismiss()
    }
    
    func config(
        showSideButtons : Bool,
        left  : String = "",
        right : String = "",
        title : String = "",
        mode  : StyleMode = .dark,
        small : Bool = false
    ){
        
        self.left  = left
        self.right = right
        self.title = title
        self.mode  = mode
        self.smallFont = small

        self.backgroundColor = self.color
        
        if showSideButtons {
             placeheader()
        } else {
            placeHeaderSparse( small )
        }
    }
    
    func setText( to str: String ){
        self.label?.text = str
        self.label2?.text = str
    }

    
    private func placeHeaderSparse( _ small: Bool){

        let f = self.frame
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 0, width: f.width-40, height: f.height)
        label.textAlignment = .center
        label.textColor = accent
        label.backgroundColor = UIColor.clear

        if small {
            label.bodyBold()
        } else {
            label.h2Icon()
        }
        
        label.text = self.title
        addSubview(label)
        self.label2 = label
    }

    
    /*
     @use: place image,text, and two pills
    */
    private func placeheader(){

        let f = self.frame
        let R = CGFloat(30)
        let button_pad : CGFloat = 24
        let W = f.width - 20 - button_pad - R

        // [BEGIN] name
        let label = VerticalAlignLabel()
        label.frame = CGRect(x: 20, y: 0, width: W, height: f.height)
        label.textAlignment = .center // .left
        label.verticalAlignment = .middle
        label.backgroundColor = UIColor.clear
        
        if self.smallFont {
            label.bodyBold()
        } else {
            if self.title == APP_NAME {
                if f.width > 350 {
                    label.h2Icon()
                } else {
                    label.h3Icon()
                }
            } else {
                if f.width > 350 {
                    label.H2()
                } else {
                    label.H3()
                }
            }
        }
        
        label.textColor = accent
        label.text = self.title
        addSubview(label)
        self.label = label

        // add button
        if right == "" { return }
        let btn = TinderButton()
        btn.frame = CGRect(x:f.width-R-button_pad, y:(f.height-R)/2,width:R,height:R)
        btn.changeImage( to: right )
        btn.backgroundColor = UIColor.clear
        btn.addTarget(self, action: #selector(onmatch), for: .touchUpInside)
        addSubview(btn)
        
    }
    


}
