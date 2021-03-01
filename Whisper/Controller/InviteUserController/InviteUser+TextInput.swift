//
//  InviteUser+TextInput.swift
//  byte
//
//  Created by Xiao Ling on 11/1/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit


extension InviteUserController : UITextFieldDelegate {

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
            isSearching = false
            return true
        } else {
            
            isSearching = true
            
            // search
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
