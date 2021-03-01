//
//  AppText.swift
//  byte
//
//  Created by Xiao Ling on 5/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- text style

enum FontClass  {
    case H1
    case H2
    case H3
    case body
    case bodyBold
    case body2
    case footer
    case footerBold
    case footerLight
}

// http://iosfonts.com/
struct FontName {
    static let icon    = "HelveticaNeue-CondensedBlack"
    static let bold    = "HelveticaNeue-Bold"
    static let regular = "HelveticaNeue-Medium"
    static let light   = "HelveticaNeue"
}


struct AppFontSize {
    static let H1       = CGFloat(35)
    static let H2       = CGFloat(25)
    static let H3       = CGFloat(20)
    static let body     = CGFloat(20)
    static let bodyBold = CGFloat(20)
    static let body2    = CGFloat(18)
    static let footer   = CGFloat(14)
    static let footerBold = CGFloat(14)
    static let footerLight = CGFloat(10)
}



extension UILabel {
    
    func icon(){
        font = UIFont(name: FontName.icon, size: AppFontSize.H1)!
        self.textColor = Color.primary_dark
    }

    func H1() {
        font = UIFont(name: FontName.bold, size: AppFontSize.H1)!
        self.textColor = Color.primary_dark
    }

    func H2() {
        font = UIFont(name: FontName.bold, size: AppFontSize.H2)!
        self.textColor = Color.primary_dark
    }
    
    
    func h2Icon(){
        font = UIFont(name: FontName.icon, size: AppFontSize.H2)!
        self.textColor = Color.primary_dark
    }
    
    func H3(){
        //header()
        font = UIFont(name: FontName.regular, size: AppFontSize.H3)!
        self.textColor = Color.primary_dark
    }
    
    func h3Icon(){
        font = UIFont(name: FontName.icon, size: AppFontSize.H3)!
        self.textColor = Color.primary_dark
    }
    
    func body(){
        font = UIFont(name: FontName.regular, size: AppFontSize.body)!
        self.textColor = Color.primary_dark
    }
    
    
    func bodyBold(){
        font = UIFont(name: FontName.bold, size: AppFontSize.H3)!
        self.textColor = Color.primary_dark
    }


    func body2(){
        font = UIFont(name: FontName.regular, size: AppFontSize.body2)!
        self.textColor = Color.primary_dark
    }

    func footer(){
        font = UIFont(name: FontName.light, size: AppFontSize.footer)!
        self.textColor = Color.grayPrimary
    }
    
    func footerBoldLarge(){
        font = UIFont(name: FontName.bold, size: 16)!
        self.textColor = Color.grayPrimary
    }

    func footerBold(){
        font = UIFont(name: FontName.regular, size: AppFontSize.footerBold)!
        self.textColor = Color.grayPrimary
    }

    
    func footerLight(){
        font = UIFont(name: FontName.light, size: AppFontSize.footerLight)!
        self.textColor = Color.grayPrimary
    }
    
    private func header(){
        textAlignment   = .center
        font  = UIFont(name: FontName.bold, size: AppFontSize.H1)!
        numberOfLines   = 0
        lineBreakMode   = .byCharWrapping
        sizeToFit()

    }
}




/*
@Use: set text and animate appeara
*/
func injectText( with str: String?, to view: UILabel?, complete: @escaping (Bool) -> Void ){
    
    if ( view == nil || str == nil ){ return complete(false) }

    view?.text  = ""
    view?.alpha = 0.3
    view?.text  = str
    
    let _ = UIViewPropertyAnimator.runningPropertyAnimator(
          withDuration: 0.5
        , delay: 0
        , options: .curveLinear
        , animations: { view?.alpha = 1.0 }
        , completion: { succ in complete(true) }
    )
}

