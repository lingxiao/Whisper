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

private enum StartCommunityState {
    case price
    case inputPrice
    case inputName
    case inputWhy
    case inputMascot
    case askFriend
    case KYC
    case socialMedia
    case transing
}

class StartCommunity: UIViewController, AppHeaderDelegate {
    
    var headerHeight: CGFloat = 80
    var statusHeight: CGFloat = 20
    var explain_dy: CGFloat = 20
    
    // view
    var pagination: UITextView?
    var header: UITextView?
    var prompt: UITextView?
    var price_l: PriceView?
    var price_c: PriceView?
    var price_r: PriceView?
    var image: UIImageView?
    var name : UITextField?
    var price: UITextField?
    var purpose: UITextField?
    var btn: TinderTextButton?
    var price_btn: TinderTextButton?
    
    var selected_price: Double = PRICE_B
    private var state : StartCommunityState = .price
        
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
    
    func onHandleDismiss() {
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
}

//MARK: - Button responders -

extension StartCommunity {
        
    //@Use: transition betweeen different views
    @objc func handleTapNext(_ button: TinderButton ){
        switch self.state {
        case .price:
            transToWhy()
        case .inputPrice:
            transToWhy()
        case .inputWhy:
            transToName()
        case .inputName:
            break;
        case .inputMascot:
            break;
        case .askFriend:
            break;
        case .KYC:
            break;
        case .socialMedia:
            break;
        case .transing:
            break;
        }
    }
    
        
    // select left price
    @objc func handleTapLeft(_ sender: UITapGestureRecognizer? = nil) {
        self.selected_price = PRICE_A
        self.price_l?.select()
        self.price_c?.unselect()
        self.price_r?.unselect()
    }
    
    // select center price
    @objc func handleTapCenter(_ sender: UITapGestureRecognizer? = nil) {
        self.selected_price = PRICE_B
        self.price_l?.unselect()
        self.price_c?.select()
        self.price_r?.unselect()
    }
    
    // select right price
    @objc func handleTapRight(_ sender: UITapGestureRecognizer? = nil) {
        self.selected_price = PRICE_A
        self.price_l?.unselect()
        self.price_c?.unselect()
        self.price_r?.select()
        self.price_l?.removeFromSuperview()
        self.price_c?.removeFromSuperview()
        self.price_r?.removeFromSuperview()
        self.layoutPriceInput(dy: self.explain_dy + 40)
        self.state = .inputPrice

    }
    
    @objc func handleTapSetPrice(_ sender: UITapGestureRecognizer? = nil) {

        let p = Double(self.price?.text ?? "\(PRICE_B)")
        self.selected_price = p ?? PRICE_B
        
        self.state = .price
        self.price?.resignFirstResponder()
        self.price?.removeFromSuperview()
        self.price_btn?.removeFromSuperview()
        layoutPrices(dy: self.explain_dy)

        self.price_l?.unselect()
        
        
        if let p = p {
            self.price_r?.setText(to: "$\(p) per week")
            self.price_c?.unselect()
            self.price_r?.select()
        } else {
            self.price_r?.setText(to: "Set your own price")
            self.price_c?.select()
            self.price_r?.unselect()
        }
    }

    
}

//MARK:- textfield:-

extension StartCommunity : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("enger: ", textField.text)
        purpose?.resignFirstResponder()
        name?.resignFirstResponder()
        return true
    }
}


//MARK:- view-

extension StartCommunity {
    
    // view transition: price => why
    private func transToWhy(){
        self.state = .inputWhy
        self.pagination?.text = "2/8"
        self.header?.text = "The Why"
        self.prompt?.text = "Tell pledges why they should join this community."
        self.price_l?.removeFromSuperview()
        self.price_c?.removeFromSuperview()
        self.price_r?.removeFromSuperview()
        self.price_btn?.removeFromSuperview()
        self.price?.removeFromSuperview()
        layoutWhyInput(dy:explain_dy+20)
    }
    
    // view transition: why => name
    private func transToName(){
        self.state = .inputName
        self.pagination?.text = "3/8"
        self.header?.text = "The Name"
        self.prompt?.text = "Short and sweet"
        purpose?.resignFirstResponder()
        purpose?.removeFromSuperview()
        layoutNameInput(dy:explain_dy+20)
    }

    
    // initaial view state
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
        h1.text = "The Price"
        view.addSubview(h1)
        h1.isUserInteractionEnabled = false
        self.header = h1
        
        dy += AppFontSize.H1 + 30
        
        // prompt
        let h2 = UITextView(frame: CGRect(x: 20, y: dy, width: f.width-40, height: AppFontSize.footerBold))
        h2.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h2.text = "Tap on a rectangle to select your weekly rate. Remember community members only pay if you both show up"
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h2.textColor = Color.primary_dark
        h2.sizeToFit()
        h2.backgroundColor = bkColor
        h2.isUserInteractionEnabled = false
        view.addSubview(h2)
        h2.center.x = view.center.x
        self.prompt = h2
            
        // layout price
        dy += AppFontSize.footerBold + 40
        self.explain_dy = dy

        
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
        ho.text = "1/8"
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
        let ht = f.height/4
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
    
    func layoutPriceInput( dy: CGFloat ){
        
        let f = view.frame
        let bw = CGFloat(80)
        let tw = f.width-80-bw
        
        let font = UIFont(name: FontName.bold, size: AppFontSize.H2)!
        let frame = CGRect(x: 30, y: dy, width: tw, height: AppFontSize.H2+20)
        let h1 = appTextField(placeholder: "Set your price", font: font, frame: frame, color: UIColor.black)
        h1.backgroundColor = bkColor
        h1.textAlignment = .left
        h1.keyboardType = .decimalPad
        h1.text = ""
        h1.delegate = self
        h1.becomeFirstResponder()
        view.addSubview(h1)
        self.price = h1
        
        let btn = TinderTextButton()
        btn.frame = CGRect(x: f.width - 20 - bw, y: dy ,width: bw, height:AppFontSize.body2+20)
        btn.config(with: "Set", color: Color.white, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn.backgroundColor = Color.redDark
        btn.addTarget(self, action: #selector(handleTapSetPrice), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.y = h1.center.y
        self.price_btn = btn

    }

    // purpose input
    func layoutWhyInput( dy: CGFloat ){
        
        let f = view.frame
        let tw = f.width-60
        
        let font = UIFont(name: FontName.bold, size: AppFontSize.body2)!
        let frame = CGRect(x: 30, y: dy, width: tw, height: AppFontSize.body2*5+20)
        let h1 = appTextField(placeholder: "What is the purpose of this community", font: font, frame: frame, color: UIColor.black)
        h1.backgroundColor = bkColor
        h1.textAlignment = .left
        h1.keyboardType = .default
        h1.text = ""
        h1.delegate = self
        h1.becomeFirstResponder()
        view.addSubview(h1)
        self.purpose = h1

    }
    
    // name input
    func layoutNameInput( dy: CGFloat ){
        let f = view.frame
        let tw = f.width-60
        let font = UIFont(name: FontName.bold, size: AppFontSize.H2)!
        let frame = CGRect(x: 30, y: dy, width: tw, height: AppFontSize.H2+20)
        let h1 = appTextField(placeholder: "Name", font: font, frame: frame, color: UIColor.black)
        h1.backgroundColor = bkColor
        h1.textAlignment = .center
        h1.keyboardType = .default
        h1.text = ""
        h1.delegate = self
        h1.becomeFirstResponder()
        view.addSubview(h1)
        self.name = h1

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
    
    func setText( to str: String ){
        self.t?.text = str
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
