//
//  StartCommunity.swift
//
//
//  Created by Xiao Ling on 3/4/21.
//


import Foundation
import UIKit
import SwiftEntryKit


private let bkColor = Color.primary

private let TEXT_1 = "write down a why"
private let TEXT_2 = "link payment to prevent scammers"
private let TEXT_3 = "define a weekly base rate"
private let TEXT_4 = "provide some social media links"

private let PRICE_A = 1.5
private let PRICE_B = 2.5

class StartCommunity: UIViewController, AppHeaderDelegate {
    
    var headerHeight: CGFloat = 80
    var statusHeight: CGFloat = 20
    
    // view
    var pagination: UITextView?
    var header: UITextView?
    var prompt: UITextView?
    var price_l: PriceView?
    var price_c: PriceView?
    var price_r: PriceView?
    var image: UIImageView?
    var name : UITextView?
    var purpose: UITextView?
    var btn: TinderTextButton?
    
    var selected_price: Double = PRICE_B
        
    override func viewDidLoad() {
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        super.viewDidLoad()
        view.backgroundColor = bkColor
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
    
    func onHandleDismiss() {
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
}

//MARK: - UGE-

extension StartCommunity {
    
    @objc func handleTapLeft(_ sender: UITapGestureRecognizer? = nil) {
        self.selected_price = PRICE_A
        self.price_l?.select()
        self.price_c?.unselect()
        self.price_r?.unselect()
    }
    
    @objc func handleTapCenter(_ sender: UITapGestureRecognizer? = nil) {
        self.selected_price = PRICE_B
        self.price_l?.unselect()
        self.price_c?.select()
        self.price_r?.unselect()
    }
    

    @objc func handleTapRight(_ sender: UITapGestureRecognizer? = nil) {
        self.selected_price = PRICE_A
        self.price_l?.unselect()
        self.price_c?.unselect()
        self.price_r?.select()
    }
    
    
}


//MARK:- view-

extension StartCommunity {

    func layout(){
        
        let f = view.frame
        var dy: CGFloat = statusHeight
        let ht  = AppFontSize.body + 30

        let h = AppHeader(frame: CGRect( x: 0, y: dy, width: f.width, height: headerHeight ))
        h.config(showSideButtons: true, left: "", right: "back", title: "Start a community", mode: .light, small: true, leftAlign: true)
        h.backgroundColor = UIColor.clear
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
        h.delegate = self
        
        dy += headerHeight + 10
        
        // header
        let h1 = UITextView(frame: CGRect(x: 15, y: dy, width: f.width-30, height: AppFontSize.H1+20))
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.font = UIFont(name: FontName.icon, size: AppFontSize.H1)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = bkColor
        h1.text = "Select your price"
        view.addSubview(h1)
        h1.isUserInteractionEnabled = false
        self.header = h1
        
        dy += AppFontSize.H1 + 30
        
        // prompt
        let h2 = UITextView(frame: CGRect(x: 20, y: dy, width: f.width-40, height: AppFontSize.footerBold))
        h2.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h2.text = "Select a weekly rate, remember community members only pay if you both show up"
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h2.textColor = Color.primary_dark
        h2.sizeToFit()
        h2.backgroundColor = bkColor
        h2.isUserInteractionEnabled = false
        view.addSubview(h2)
        h2.center.x = view.center.x
        self.prompt = h1
            
        // layout price
        dy += AppFontSize.footerBold + 40
        layoutPrices(dy: dy)
        
        dy += f.height/4 + 20
        
        // pagination
        let pdy = f.height - ht - 50 - AppFontSize.H2
        let ho = UITextView(frame: CGRect(x: 15, y: pdy, width: f.width-30, height: AppFontSize.H2))
        ho.textAlignment = .center
        ho.textContainer.lineBreakMode = .byTruncatingTail
        ho.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        ho.textColor = Color.primary_dark
        ho.backgroundColor = bkColor
        ho.text = "1/3"
        view.addSubview(ho)
        ho.isUserInteractionEnabled = false
        self.pagination = ho

        // button
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width*0.40, height:ht)
        btn.config(with: "Next", color: Color.white, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn.backgroundColor = Color.black.lighter(by: 10)
        btn.addTarget(self, action: #selector(handleTapNext), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.x = view.center.x
        self.btn = btn
    }
    
    private func layoutPrices( dy : CGFloat ){
        
        let f = view.frame
        let wd = (f.width - 30)/3
        let ht = f.height/4 // - dy - AppFontSize.body + 30 + 50
        var dx  = CGFloat(15)
         
        //left
        let vl = PriceView(frame: CGRect(x: dx, y: dy, width: wd, height: ht))
        vl.config(str: "$\(PRICE_A)0 per week")
        vl.roundCorners(corners: [.topLeft,.bottomLeft], radius: 5)
        view.addSubview(vl)
        dx += wd
        
        // cennter
        let vc = PriceView(frame: CGRect(x: dx, y: dy, width: wd, height: ht))
        vc.config(str: "$\(PRICE_B)0 per week")
        view.addSubview(vc)
        vc.select()
        dx += wd
        
        // right
        let vr = PriceView(frame: CGRect(x: dx, y: dy, width: wd, height: ht))
        vr.config(str: "Set your own price")
        vr.roundCorners(corners: [.bottomRight,.topRight], radius: 5)
        view.addSubview(vr)

        
        vl.center.y = view.center.y
        vc.center.y = view.center.y
        vr.center.y = view.center.y


        self.price_l = vl
        self.price_c = vc
        self.price_r = vr

        // responders
        let tapl = UITapGestureRecognizer(target: self, action: #selector(handleTapLeft))
        vl.addGestureRecognizer(tapl)
        let tapc = UITapGestureRecognizer(target: self, action: #selector(handleTapCenter))
        vc.addGestureRecognizer(tapc)
        let tapr = UITapGestureRecognizer(target: self, action: #selector(handleTapRight))
        vr.addGestureRecognizer(tapr)

    }

    
    private func layoutOne( str: String, dy: CGFloat )  -> CGFloat {

        let f = view.frame
        var dx = CGFloat(20)
        let r  = AppFontSize.H2
        
        let btn = TinderButton()
        btn.frame = CGRect(x:dx, y:dy + 10 ,width:r, height:r)
        btn.changeImage(to: "star", alpha: 1.0, scale: 1.0, color: Color.primary_dark)
        btn.backgroundColor = bkColor
        view.addSubview(btn)
        
        dx += r + 5
        
        let h2 = UITextView(frame: CGRect(x: dx, y: dy, width: f.width-20-dx, height: AppFontSize.footer))
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.light, size: AppFontSize.H2)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = bkColor
        h2.text = str
        h2.sizeToFit()
        view.addSubview(h2)
        let ht2 = h2.sizeThatFits(h2.bounds.size).height
        
        btn.center.y = h2.center.y

        return ht2
        
    }
    
}


//MARK:- price view -

class PriceView : UIView {
    
    var t : UITextView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
        
    func select(){
        self.backgroundColor = Color.black
        t?.textColor = Color.white
    }
    
    func unselect(){
        self.backgroundColor = Color.grayQuaternary
        t?.textColor = Color.black
    }

    
    func config( str: String ){
        
        let f = self.frame
        let wd = f.width
        let ht = f.height
        let wd2 = wd - 10
        let ht2 = AppFontSize.H3*3
        let dy2 = (ht-ht2)/2
        
        self.backgroundColor = Color.grayQuaternary
        
        let tr = UITextView(frame: CGRect(x: (wd-wd2)/2, y: dy2, width: wd2, height: ht2))
        tr.textAlignment = .center
        tr.textContainer.lineBreakMode = .byWordWrapping
        tr.text = str
        tr.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        tr.textColor = Color.black
        tr.isUserInteractionEnabled = false
        tr.backgroundColor = UIColor.clear
        self.addSubview(tr)
        self.t = tr
    }
}
