//
//  OnboardEntry.swift
//  Whisper
//
//  Created by Xiao Ling on 3/4/21.
//


import Foundation
import UIKit
import SwiftEntryKit


private let bkColor = Color.primary

private let TITLE_1 = "How we work"
private let TITLE_2 = "How payment work"


class OnboardEntry: UIViewController, NumberPadControllerDelegateOnboard {
    
    var headerHeight: CGFloat = 80
    var textHt: CGFloat = 40
    var statusHeight: CGFloat = 20
    
    // views
    var head : UITextView?
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
            self.head?.text = TITLE_2
            self.text?.text = UserAuthed.shared.onboard_message_2
            self.btn?.textLabel?.text = "Start"
            self.pos = 1
        } else {
            self.pos = 2
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
        h1.text = "The simplest way to sustainably grow and finance niche communities"
        h1.sizeToFit()
        view.addSubview(h1)

        let ht1 = h1.sizeThatFits(h1.bounds.size).height
        
        dy += ht1 + 25
        
        let ht2 = f.height - dy - ht - 50 - 20
        let v = UIView(frame: CGRect(x: 15, y: dy, width: f.width-30, height: ht2))
        v.applyShadowWithCornerRadius(color: bkColor.darker(by: 35), opacity: 0.5, cornerRadius: 25, radius: 2, edge: AIEdge.Bottom_Right, shadowSpace: 2)
        v.backgroundColor = UIColor.white
        view.addSubview(v)
        let pf = v.frame
        
        // title
        let h2 = UITextView(frame: CGRect(x: 20, y: 20, width: pf.width-40, height: AppFontSize.H1))
        h2.textAlignment = .left
        h2.text = TITLE_1
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = UIColor.white
        h2.isUserInteractionEnabled = false
        v.addSubview(h2)
        self.head = h2
        
        // explain
        let ht3 = ht2 - 20 - AppFontSize.H1 - 40
        let h3 = UITextView(frame: CGRect(x: 20, y: AppFontSize.H1+30, width: pf.width-40, height: ht3))
        h3.textAlignment = .left
        h3.text = UserAuthed.shared.onboard_message_1
        h3.font = UIFont(name: FontName.light, size: AppFontSize.body2)
        h3.textColor = Color.primary_dark
        h3.backgroundColor = UIColor.white
        h3.isUserInteractionEnabled = false
        v.addSubview(h3)
        self.text = h3
        
        // button
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width*0.40, height:ht)
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



