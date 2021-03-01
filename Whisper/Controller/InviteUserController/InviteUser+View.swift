//
//  InviteUser+View.swift
//  byte
//
//  Created by Xiao Ling on 11/1/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


extension InviteUserController {
    
    func placeNavHeader(){
        let f = view.frame
        let frame = CGRect( x: 0, y: statusHeight, width: f.width, height: headerHeight )
        let h = AppHeader(frame: frame)
        h.config( showSideButtons: true, left: "", right: "xmark", title: self.header, mode: .light )
        h.delegate = self
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
        self.appNavHeader = h
    }


    func setUpSearch( _ showHeader: Bool ){
        
        let f = view.frame
        let dy = showHeader ? headerHeight + statusHeight + pad_top : pad_top

        let view = UIView( frame: CGRect(x:0, y: dy, width:f.width, height: searchHeight))

        let inputTextField = PaddedTextField(frame: CGRect(
              x: 10
            , y: 0
            , width : f.width - 20
            , height: searchHeight
        ))

        inputTextField.placeholder = "Search"
        inputTextField.backgroundColor = base
        inputTextField.font = UIFont( name: FontName.bold, size: AppFontSize.footerBold )
        inputTextField.borderStyle = UITextField.BorderStyle.none
        inputTextField.keyboardType = UIKeyboardType.default
        inputTextField.returnKeyType = UIReturnKeyType.done
        inputTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        
        // border
        inputTextField.layer.cornerRadius = 15
        inputTextField.layer.borderWidth = 0.5
        inputTextField.layer.borderColor = Color.grayTertiary.cgColor

        // mount and delegate
        view.addSubview(inputTextField)
        inputTextField.delegate = self
        self.view.addSubview(view)
        self.inputTextField = inputTextField
        
    }
    
    func placeInviteBtn( _ str: String ){
        
        let f  = self.view.frame
        let wd = f.width * 0.30
        let ht = CGFloat(40)

        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:0,width:wd,height:ht*1.1)
        btn.config(with: str)
        btn.addTarget(self, action: #selector(onPressCenterBtn), for: .touchUpInside)

        btn.center.y = f.height - computeTabBarHeight() - 5
        btn.center.x = self.view.center.x
        
        view.addSubview(btn)
        self.inviteBtn = btn
    }


    
}
