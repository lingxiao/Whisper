//
//  PhoneBook+Text.swift
//  byte
//
//  Created by Xiao Ling on 2/15/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

extension PhoneBookController : UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // return NO to disallow editing.
        // print("TextField should begin editing method called")
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // became first responder
        // print("TextField did begin editing method called")
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
        // print("TextField should snd editing method called")
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
        // print("TextField did end editing method called")
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        // if implemented, called in place of textFieldDidEndEditing:
        // print("TextField did end editing with reason method called")
    }

    /*
     @use: build current input and query database
     */
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // return NO to not change text
        //print("While entering the characters this method gets called with: \(textField.text)")
                
        guard let stub = textField.text else {
            isSearching = false
            return true
        }
            
        var name : String = ""
        if string == "" {
            name = String(stub.dropLast())
        } else {
            name = "\(stub)\(string)"
        }
        
        if name == "" {
            self.isSearching = false
            return true

        } else {
            self.isSearching = true
            let reduced = dataSource.filter{ $0.match( query: name ) }
            self.filteredDataSource = reduced
            self.tableView?.reloadData()
            return true
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        // called when clear button pressed. return NO to ignore (no notifications)
        // print("TextField should clear method called")
        return true
    }

    /*
     @use: strip down
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // called when 'return' key pressed. return NO to ignore.
        isSearching = false
        inputTextField?.resignFirstResponder()
        inputTextField?.text = ""
        tableView?.reloadData()
        filteredDataSource = []
        return false
    }

}



//MARK:- other views

extension PhoneBookController {
    
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

        inputTextField.placeholder = "Search Contacts"
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
