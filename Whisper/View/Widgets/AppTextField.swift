//
//  AppTextField.swift
//  byte
//
//  Created by Xiao Ling on 5/23/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import UIKit
import Foundation



//MARK:- text input with left and right padding

class PaddedTextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}


// app standard text field
func appTextField( placeholder: String, font: UIFont, frame: CGRect, color: UIColor, placeHolderColor: UIColor = Color.grayPrimary ) -> UITextField {

    let field : UITextField = UITextField()
    field.frame              = frame
    field.textAlignment      = .center
    field.keyboardType       = UIKeyboardType.default
    field.returnKeyType      = UIReturnKeyType.done
    field.autocorrectionType = UITextAutocorrectionType.no
    field.borderStyle        = UITextField.BorderStyle.none
    field.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
    field.textColor = color
    field.font = font
    field.textAlignment = .center
    
    field.attributedPlaceholder = NSAttributedString(
          string: placeholder
        , attributes: [NSAttributedString.Key.foregroundColor: placeHolderColor]
    )
    
    return field
}
