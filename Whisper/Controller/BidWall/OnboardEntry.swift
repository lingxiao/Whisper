//
//  OnboardEntry.swift
//  Whisper
//
//  Created by Xiao Ling on 3/4/21.
//


import Foundation
import UIKit
import SwiftEntryKit


private let bkColor = Color.secondary

private let TEXT_1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis blandit posuere lacus, vel pharetra libero volutpat a. Quisque enim arcu, gravida quis libero a, vulputate porttitor eros. Praesent nec felis nec justo sollicitudin volutpat ac sed turpis. Fusce ut velit eu orci pretium scelerisque nec vel nulla. Praesent lacinia massa non nulla ullamcorper, non vulputate mauris aliquet. Sed sit amet volutpat odio. Donec eget orci sit amet urna lacinia commodo. Sed eget augue non ligula pharetra aliquet at vitae velit. Curabitur luctus felis sodales, porttitor neque elementum, blandit purus. Integer luctus tristique nisi sed suscipit. Nunc rutrum interdum tellus."

private let TEXT_2 = "Praesent sodales quam id bibendum interdum. Sed euismod pretium porta. Vestibulum vel mi luctus, porttitor nulla eu, condimentum massa. Aenean sollicitudin maximus est at molestie. Praesent accumsan aliquet accumsan. Etiam fermentum ligula non magna semper, sit amet auctor quam tincidunt. Ut ut sodales massa, ac viverra enim. In quis bibendum ex."

class OnboardEntry: UIViewController, NumberPadControllerDelegateOnboard {
    
    var headerHeight: CGFloat = 80
    var textHt: CGFloat = 40
    var statusHeight: CGFloat = 20
    
    // views
    var text : UITextView?
    var btn  : TinderTextButton?
    var pos  : Int = 0
    
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

    
    @objc func handleGoBack(_ button: TinderButton ){
        
        if pos == 0 {
            self.text?.text = TEXT_2
        } else {
            print(">> next")
        }
        /*let vc = NumberPadController()
        vc.view.frame = UIScreen.main.bounds
        vc.config(with: "Enter referral code", showHeader: true, isHome: true)
        vc.onboardDelegate = self
        view.addSubview(vc.view)
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)*/
    }
    
    /*
     @use: after syncing with sponsor, either go to home page or to additional onboarding steps
     */
    func onDidSyncWithSponsor( at code: String, with club: Club? ){

        let name = club?.getOrg()?.get_H1() ?? "the server"
        ToastSuccess(title: "Confirmed with \(name)", body: "Give us a few seconds while we sync with the server")
        
        UserAuthed.shared.syncWithSponsor(at:code){ sponsor in
            
            // have onboarded,do not do it again
            AuthDelegate.shared.doNotOnboard()
            
//            // wait for db to sync, then determine if additional onboarding steps needed
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
//                SwiftEntryKit.dismiss()
//                if let org = club?.getOrg() {
//                    if org.bespokeOnboard && ClubList.shared.fetchTags(for: org).count > 0 {
//                        let vc = OnboardCommunController()
//                        vc.view.frame = UIScreen.main.bounds
//                        vc.config(with:club)
//                        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
//                    } else {
//                        AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
//                    }
//                } else {
//                    AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
//                }
//            }
        }
    }
    
    func layout(){
        
        let f = view.frame
        var dy: CGFloat = statusHeight
        let ht  = AppFontSize.body + 30

        let h = AppHeader(frame: CGRect( x: 0, y: dy, width: f.width, height: headerHeight ))
        h.config(showSideButtons: false, title: "Welcome to \(APP_NAME)", leftAlign: true)
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
        h1.text = "The simplest way to sustainably grow and finance communities"
        h1.sizeToFit()
        view.addSubview(h1)

        let ht1 = h1.sizeThatFits(h1.bounds.size).height
        
        dy += ht1 + 25
        
        let ht2 = f.height - dy - ht - 50 - 20
        let v = UIView(frame: CGRect(x: 15, y: dy, width: f.width-30, height: ht2))
        v.applyShadowWithCornerRadius(color: bkColor.darker(by: 35), opacity: 1.0, cornerRadius: 25, radius: 2, edge: AIEdge.All, shadowSpace: 15)
        v.backgroundColor = UIColor.white
        view.addSubview(v)
        let pf = v.frame
        
        // title
        let h2 = UITextView(frame: CGRect(x: 20, y: 10, width: pf.width-40, height: AppFontSize.H1))
        h2.textAlignment = .left
        h2.text = "How it works"
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h2.textColor = Color.primary_dark
        v.addSubview(h2)
        
        // explain
        let h3 = UITextView(frame: CGRect(x: 20, y: AppFontSize.H1+30, width: pf.width-40, height: AppFontSize.H1))
        h3.textAlignment = .left
        h3.text = TEXT_1
        h3.font = UIFont(name: FontName.light, size: AppFontSize.body2)
        h3.textColor = Color.primary_dark
        h3.sizeToFit()
        v.addSubview(h3)
        self.text = h3
        
        // button
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width/2, height:ht)
        btn.config(
            with: "Tell me more",
            color: Color.primary_dark,
            font: UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        )
        btn.addTarget(self, action: #selector(handleGoBack), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.x = view.center.x
        self.btn = btn
    }
    
    
    

}









/*
 func _populate(){
     
     let f = view.frame
     
     guard let me = UserList.shared.yieldMyself() else { return }
     
     var dy = CGFloat(50) + headerHeight + statusHeight
     let R  = f.width/2

     // place image
     let profileImg = UIImageView(frame: CGRect(x:0,y:dy,width:R,height:R))
     let _ = profileImg.round()
     profileImg.backgroundColor = Color.grayQuaternary
     profileImg.center.x = self.view.center.x
     self.view.addSubview(profileImg)
     self.img = profileImg
     
     // tap icon or profile image url
     if let url = UserAuthed.shared.fetchThumbURL() {
         ImageLoader.shared.injectImage(from: url, to: profileImg){ _ in return }
     } else {
         let r = AppFontSize.H2
         let add_sign = UILabel(frame: CGRect(x: 0, y: dy + R/2-r/2, width:r, height: r))
         add_sign.text = "+"
         add_sign.font = UIFont(name: FontName.bold, size: AppFontSize.H2)
         add_sign.textColor = Color.primary_dark
         view.addSubview(add_sign)
         add_sign.center.x = self.view.center.x
         self.add_sign = add_sign
         view.bringSubviewToFront(add_sign)
     }
     
     // events
     profileImg.isUserInteractionEnabled = true
     let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapImage(_:)))
     profileImg.addGestureRecognizer(tap)

     dy += R/2 + 20
     
     let t1 = placeInput(logo: "", placeHolder: "Name", val: me.get_H1(), dy: dy)
     self.name = t1

     dy = dy + textHt + 5

     // place bio
     //placeBio(dy: dy)
     
     // button
     let ht  = AppFontSize.body + 30
     let btn = TinderTextButton()
     btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width/2, height:ht)
     btn.config(
         with: "Sync with sponsor",
         color: Color.primary_dark,
         font: UIFont(name: FontName.bold, size: AppFontSize.footerBold)
     )
     btn.addTarget(self, action: #selector(handleGoBack), for: .touchUpInside)
     view.addSubview(btn)
     btn.center.x = view.center.x
 }


 
 */
