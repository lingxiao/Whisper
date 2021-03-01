//
//  SignInController.swift
//  byte
//
//  Created by Xiao Ling on 12/9/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import NVActivityIndicatorView


private let email_prompt  = "Please enter your email"
private let code_prompt   = "6 character referral code"

class SignInController : UIViewController {

    //data
    var code : String = ""
    var email: String = ""
    
    //view
    var statusHeight : CGFloat = 40.0

    // view
    var codeTextField: UITextField?
    var awaitView: NVActivityIndicatorView?
    var btn: TinderTextButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.primary
        placeNavHeader()
        placeInputCode()
        codeTextField?.becomeFirstResponder()
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }

    }
    
    private func validEmail( _ str: String? ) -> Bool {
        guard let str = str else { return false }
        let email = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return checkValidEmail(email)
    }
    
    private func validCode(_ str: String? ) -> Bool {
        guard let str = str else { return false }
        return str.count == 6
    }
        
}

//MARK:- textfield

extension SignInController : UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                
        if validEmail(textField.text) {
            
            if let str = textField.text {
                self.email = str
            }
            
            // set
            AuthDelegate.shared.doGoOnBoard()
            
            // disable view
            placeIndicator(type: .ballBeat, label: "")
            self.codeTextField?.isUserInteractionEnabled = false
            codeTextField?.placeholder = "Connecting"
            codeTextField?.text = ""
            
            AuthDelegate.shared.authenticate(with: email, phone: ""){ (succ, msg ) in
                if ( !succ ){
                    ToastSuccess(title: "Oh no!", body: "An error occured: \(msg)")
                    self.codeTextField?.isUserInteractionEnabled = true
                    self.removeIndicator()
                    self.codeTextField?.placeholder = email_prompt
                    self.codeTextField?.text = self.email
                }
            }
            
            return false
            
        } else {

            ToastSuccess(title: "Invalid email", body: "Please try again")
            return false
        }
    }
}



//MARK:- view

extension SignInController {
   
    func placeInputCode(){
        let f = view.frame
        let fheader = UIFont(name: FontName.bold, size: AppFontSize.body)!
        let rect    = CGRect(x: 0, y: 0, width: f.width, height: 80 )
        let h1 = appTextField(placeholder: email_prompt, font: fheader, frame: rect, color: Color.primary_dark  )
        h1.attributedPlaceholder = NSAttributedString(
              string: email_prompt
            , attributes: [NSAttributedString.Key.foregroundColor: Color.grayPrimary
        ])
        h1.keyboardType = .default
        h1.isUserInteractionEnabled = true
        h1.center.x = self.view.center.x
        h1.center.y = self.view.center.y - 80/2
        h1.delegate = self
        self.codeTextField = h1
        view.addSubview(h1)
    }
    
    
    private func placeIndicator( type: NVActivityIndicatorType, label: String ){
        let f = self.view.frame
        let R = f.width/9
        let frame = CGRect( x: 0, y: 0, width: R, height: R )
        let v = NVActivityIndicatorView(frame: frame, type: type , color: Color.primary_dark, padding: 0)
        self.view.addSubview(v)
        self.view.bringSubviewToFront(v)
        v.center = self.view.center
        v.startAnimating()
        self.awaitView = v
    }


    func placeNavHeader(){
        let f = view.frame
        let frame = CGRect( x: 0, y: statusHeight, width: f.width-20, height: 80 )
        let h = AppHeader(frame: frame)
        h.config( showSideButtons: false, left : "", right: "", title: "Sign In" )
        h.backgroundColor = UIColor.clear
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
        h.center.x = self.view.center.x
    }

    private func removeIndicator(){
        self.awaitView?.removeFromSuperview()
        self.awaitView = nil
    }

}


