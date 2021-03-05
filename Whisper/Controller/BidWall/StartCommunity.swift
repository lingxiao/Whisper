//
//  StartCommunity.swift
//
//
//  Created by Xiao Ling on 3/4/21.
//


import Foundation
import UIKit
import SwiftEntryKit


private let bkColor = UIColor.clear //Color.primary

private let TEXT_1 = "1. Write down a why so prospective members understand the purpose of this community."
private let TEXT_2 = "2. Verify you're real by validating your deposit and payment information. Strong KYC (know your customer) protects the community from scammers."
private let TEXT_3 = "3. Define a starting weekly rate to screen out everyone who is not committed to your cause."



class StartCommunity: UIViewController {
    
    var headerHeight: CGFloat = 80
    var textHt: CGFloat = 40
    var statusHeight: CGFloat = 20
    
    // views
    var head : UITextView?
    var text : UITextView?
    var card : UIView?
    var btn  : TinderTextButton?
    var vl   : UIView?
    var vr   : UIView?
    var h1   : UITextView?
    var pos  : Int = 0
    
    override func viewDidLoad() {
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        super.viewDidLoad()
        //view.backgroundColor = bkColor
        primaryGradient(on: self.view)
        layout()
    }
    
    func config(){ return }

    
    @objc func handleTapNext(_ button: TinderButton ){


        /*let vc = NumberPadController()
        vc.view.frame = UIScreen.main.bounds
        vc.config(with: "Enter referral code", showHeader: true, isHome: true)
        vc.onboardDelegate = self
        view.addSubview(vc.view)
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)*/
    }
    
    @objc func handleTapRight(_ sender: UITapGestureRecognizer? = nil) {
        func fn(){ self.vr?.alpha = 0.5 }
        func gn(){ self.vr?.alpha = 1.0 }
        runAnimation( with: fn, for: 0.15 ){
            runAnimation( with: gn, for: 0.15 ){ return }
        }
    }

    @objc func handleTapLeft(_ sender: UITapGestureRecognizer? = nil) {
        func fn(){ self.vl?.alpha = 0.5 }
        func gn(){ self.vl?.alpha = 1.0 }
        runAnimation( with: fn, for: 0.15 ){
            runAnimation( with: gn, for: 0.15 ){ return }
        }
    }
    

    func layout(){
        
        let f = view.frame
        var dy: CGFloat = statusHeight
        let ht  = AppFontSize.body + 30

        let h = AppHeader(frame: CGRect( x: 0, y: dy, width: f.width, height: headerHeight ))
        h.config(showSideButtons: true, left: "", right: "back", title: "Get ready", mode: .light, small: true, leftAlign: true)
        h.backgroundColor = UIColor.clear
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
        
        dy += headerHeight + 25

        let h1 = UITextView(frame: CGRect(x: 15, y: dy, width: f.width-30, height: AppFontSize.footer))
        h1.textAlignment = .left
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.font = UIFont(name: FontName.icon, size: AppFontSize.H1)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = bkColor
        h1.text = "We are going to:"
        h1.sizeToFit()
        view.addSubview(h1)

        let ht1 = h1.sizeThatFits(h1.bounds.size).height
        dy += ht1 + 25
        
        let ht2 = layoutOne(str: TEXT_1, dy: dy)
        dy += ht2 + 10
        
        let ht3 = layoutOne(str: TEXT_2, dy: dy)
        dy += ht3 + 10

        let ht4 = layoutOne(str: TEXT_3, dy: dy)
        dy += ht4 + 10

        // button
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width*0.40, height:ht)
        btn.config(
            with: "Tell me more",
            color: Color.primary_dark,
            font: UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        )
        btn.addTarget(self, action: #selector(handleTapNext), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.x = view.center.x
        self.btn = btn
                
    }
    
    private func layoutOne( str: String, dy _dy: CGFloat )  -> CGFloat {

        let f = view.frame
        var dy = _dy
        var dx = CGFloat(15)
        let r  = AppFontSize.H2
        
        let btn = TinderButton()
        btn.frame = CGRect(x:dx, y:dy ,width:r, height:r)
        btn.changeImage(to: "xmark", alpha: 1.0, scale: 2/3, color: Color.blue1)
        view.addSubview(btn)
        
        dx += r + 5
        
        let h2 = UITextView(frame: CGRect(x: dx, y: dy, width: f.width-20-dx, height: AppFontSize.footer))
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = bkColor
        h2.text = str
        h2.sizeToFit()
        view.addSubview(h2)
        let ht2 = h2.sizeThatFits(h2.bounds.size).height

        return ht2
        
    }
    
}