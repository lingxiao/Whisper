//
//  SplashPages.swift
//  byte
//
//  Created by Xiao Ling on 12/9/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- constants + protocol

let intro = "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like)."

let nocam = "he point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text."

protocol SplashPageProtocol {
    func goToPageTwo() -> Void
}


//MARK:- page one

// welcome page
class SplashOne : UIViewController {
    
    var delegate: SplashPageProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryGradient(on: view)
        layout()
    }
    
    func layout(){

        let f  = view.frame
        var dy = CGFloat(100)
        
        // header
        let label : UILabel = UILabel(frame: CGRect(x: 0, y: dy, width: f.width, height: AppFontSize.H1*2))
        label.textAlignment = .center
        label.H1()
        label.textColor = Color.primary_dark
        label.text = "Welcome!"
        view.addSubview(label)
        
        dy += AppFontSize.H1*2 + 20
            
        let h2 = UITextView(frame: CGRect(x:20,y:dy,width:f.width-40,height:AppFontSize.body))
        h2.font = UIFont(name: FontName.regular, size: AppFontSize.body)
        h2.text = intro
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.isUserInteractionEnabled = false
        h2.sizeToFit()
        h2.backgroundColor = UIColor.clear
        h2.textColor = Color.primary_dark.lighter(by: 5)
        view.addSubview(h2)
        
        // button
        let ht  = AppFontSize.body + 30
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width/3,height:ht)
        btn.config(with: "Next")
        btn.addTarget(self, action: #selector(handleTapInvite), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.x = view.center.x
    }
    
    @objc func handleTapInvite(_ button: TinderButton ){
        let f = view.frame
        let vc = SplashTwo()
        vc.view.frame = CGRect(x:0,y:0,width:f.width,height:f.height)
        AuthDelegate.shared.loginController?.navigationController?.pushViewController(vc, animated: true)
    }

}


//MARK:- page two

// statement of purpose
class SplashTwo : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryGradient(on: view)
        layout()
    }
    
    func layout(){

        let f = view.frame
        let R = f.width/3

        // text
        let h2 = UITextView(frame: CGRect(x:20,y:0,width:f.width-40,height:AppFontSize.body))
        h2.font = UIFont(name: FontName.regular, size: AppFontSize.body)
        h2.text = nocam
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.isUserInteractionEnabled = false
        h2.sizeToFit()
        h2.backgroundColor = UIColor.clear
        h2.textColor = Color.primary_dark.lighter(by: 5)
        view.addSubview(h2)
        h2.center.y = view.center.y
        
        // image
        let v = UIImageView(image: UIImage(named: "nocamera")!)
        v.frame = CGRect(x:0,y:0,width:R,height:R)
        view.addSubview(v)
        v.center.x = view.center.x
        v.center.y = view.center.y - h2.frame.height/2 - 80
        
        // button
        let ht  = AppFontSize.body + 30
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width/3,height:ht)
        btn.config(with: "Sign in")
        btn.addTarget(self, action: #selector(handleTapInvite), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.x = view.center.x
    }

    @objc func handleTapInvite(_ button: TinderButton ){
        let f = view.frame
        let vc = SignInController()
        vc.view.frame = CGRect(x:0,y:0,width:f.width,height:f.height)
        AuthDelegate.shared.loginController?.navigationController?.pushViewController(vc, animated: true)
    }
}


//MARK:- page three

// no screen shots
class LoginThreeController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

