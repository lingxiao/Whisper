//
//  HomeController.swift
//  byte
//
//  Created by Xiao Ling on 7/8/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import NVActivityIndicatorView
import AVFoundation



class HomeController: UIViewController, UINavigationControllerDelegate {
    
    // @use: display states
    var appIsForeGround: Bool = false
    
    // view style props
    var statusHeight : CGFloat = 10.0
    var footerHeight: CGFloat = 60.0
    
    // modal views
    var blurView   : UIView?
    var blurWidget : NVActivityIndicatorView?
    var awaitView  : AwaitWidget?
    var resumeView : ResumeView?
    var newClubView: ClubHomeDirCell?
    var phoneNumberView: PhoneNumberView?
    
    var darkView : UIView?
    var newCohortView: NewCohortView?

    // no content view
    var emptyLabel : UITextView?
    var headerLabel: UITextView?
    var refreshBtn : TinderButton?

    // slide out accessory view
    var leftFeed: OrgListController?
    
    // main child views
    var newsFeed  : ClubDirectoryController?
    var alertFeed : AlertController?
    var padView   : NumberPadController?
    var profileVw : ProfileController?
    var footer    : HomeFooter?
    
    // onboarding + state
    var isLoading: Bool = false
    var didShowOnBoard: Bool = false
    var isCreatingRoom: Bool = false
    
    // We are willing to become first responder to get shake motion
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
        
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
        self.appIsForeGround = true
        self.becomeFirstResponder()
        observeAppEvents()
        addGestureResponders()
        listenIdidJoinOrLeaveRoom(on: self, for: #selector(didJoinOrLeaveRoom))
        listenRefreshNewsFeed(on:self, for: #selector(refreshTopLevelNewsFeed))

        // await data load, then hide blur view
        showSplash(){
            self.isLoading = true
            self.reload(){
                self.hideSplash(){
                    self.isLoading = false
                    if let v = self.newsFeed?.view {
                        self.newsFeed?.view.bringSubviewToFront(v)
                    }
                    if let vf = self.footer {
                        self.view.bringSubviewToFront(vf)
                    }
                }
            }
            
            // Hack: until they sign back in,do not make these bespoke account redo onboarding
            if ["RWEhYwXou2RnnUmpdZxEKtLL2YK2"].contains(UserAuthed.shared.uuid){
                self.didShowOnBoard = true
                return
            } else {
                // if I have not been onboarded yet, then go onboard
                if AuthDelegate.shared.shouldOnBoard && !self.didShowOnBoard {
                    self.didShowOnBoard = true
                    self.goOnboard()
                }
            }
        }
            
    }
    
    
    // @use: complete onboarding view
    private func goOnboard(){
        let vc = FinishOnboardController()
        vc.view.frame = UIScreen.main.bounds
        vc.config()
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleRefresh(_ button: TinderButton ){
        reload(){ return }
    }
    
    func reload(_ then: @escaping() -> Void ){
        loopReload(for: 2){ then() }
    }
    
    
    // @todo: remove this call back, and just do 3second timeoutyou
    // either get the data or do not and show reload button.
    private func loopReload(for n: Int, _ then: @escaping() -> Void ){
     
        let item : (OrgModel,[Club])? = ClubList.shared.fetchPriorityOrg()
 
        if n <= 0 {
            if item == nil {
                layoutEmpty()
                then()
            } else {
                then()
            }
        } else {
            if let item = item {
                removeEmpty()
                layoutViews( with: item, offset: false )
                then()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 ) { [weak self] in
                    self?.loopReload(for: n - 1){ then() }
                }
            }
        }
    }
}




//MARK:- view

extension HomeController {
    
    // layout homeview
    func layoutViews( with data: (OrgModel,[Club]), offset: Bool ){
            
        let f = view.frame
        let bkColor = UIColor.white
        self.view.backgroundColor = bkColor
        
        // home page
        let dx = offset ? f.width*3/4 : 0
        let (org,clubs) = data

        if self.newsFeed != nil {
            self.newsFeed?.view.removeFromSuperview()
            self.newsFeed = nil
        }
        let vc = ClubDirectoryController()
        vc.view.frame = CGRect(x: dx, y: 0, width: f.width, height: f.height-footerHeight)
        vc.config(with: org, clubs: clubs, parentVC: nil)
        vc.delegate = self
        view.addSubview(vc.view)
        self.newsFeed = vc
        
        layoutFooter( dx: dx )
    }
    
    func layoutFooter( dx: CGFloat ){
        
        let f = view.frame
        let bkColor = UIColor.white

        // footer
        if self.footer !== nil {
            self.footer?.removeFromSuperview()
            self.footer = nil
        }
        let footer = HomeFooter(frame:CGRect(x: dx, y: f.height-footerHeight, width: f.width, height: footerHeight))
        footer.config( with: bkColor )
        footer.delegate = self
        view.addSubview(footer)
        footer.center.x = self.view.center.x
        self.footer = footer
    }
    

    // on swipe right, show left drawer view
    func onSwipeRight(){
        
        let f = view.frame
        let dx = f.width*3/4
        if self.leftFeed == nil {
            let cv = OrgListController()
            cv.view.frame = CGRect(x: -dx, y: 0, width: dx, height: f.height)
            cv.config(width:dx)
            cv.delegate = self
            view.addSubview(cv.view)
            self.leftFeed = cv
        }
        
        func fn(){
            guard let lvc = self.leftFeed else { return }
            guard let vc = self.newsFeed else { return }
            lvc.view.frame = CGRect(x: 0, y: 0, width: dx, height: f.height)
            vc.view.frame  = CGRect(x: dx, y: 0, width: f.width, height: f.height-footerHeight)
            self.footer?.frame = CGRect(x: dx, y: f.height-footerHeight, width: f.width, height: footerHeight)
        }

        runAnimation( with: fn, for: 0.25 ){ return }
    }

    // on swipe left, remove left drawwer view
    func onSwipeLeft(){
        let f = view.frame
        let dx = f.width*2/3
        func fn(){
            self.leftFeed?.view.frame = CGRect(x: -dx, y: 0, width: dx, height: f.height)
            self.newsFeed?.view.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height-footerHeight)
            self.footer?.frame = CGRect(x: 0, y: f.height-footerHeight, width: f.width, height: footerHeight)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.leftFeed?.view.removeFromSuperview()
            self.leftFeed = nil
        }
    }
    
    // remove labels indicating no content
    private func removeEmpty(){
        self.emptyLabel?.removeFromSuperview()
        self.refreshBtn?.removeFromSuperview()
        self.headerLabel?.removeFromSuperview()
    }
    
    // layout view stating the user has no content
    private func layoutEmpty(){

        removeEmpty()
        self.newsFeed?.view.removeFromSuperview()
        self.leftFeed?.view.removeFromSuperview()
        
        let f = view.frame
        let ht = AppFontSize.H3*2
        
        let label = UITextView()
        label.frame = CGRect(x: 20, y: 60, width: f.width-40, height: AppFontSize.H1+20)
        label.textAlignment = .center
        label.textColor = Color.primary_dark.darker(by: 25)
        label.font = UIFont(name: FontName.icon, size: AppFontSize.H1)
        label.text = APP_NAME
        label.backgroundColor = UIColor.clear
        view.addSubview(label)
        self.headerLabel = label

        let r = CGFloat(40)
        let b = TinderButton()
        b.frame = CGRect(x: 0, y: 0, width: r, height: r)
        b.changeImage(to: "reload", alpha: 1.0, scale: 1.0, color: Color.primary_dark)
        b.backgroundColor = UIColor.clear
        b.center.x = self.view.center.x
        b.center.y = self.view.center.y - r - 10
        view.addSubview(b)
        self.refreshBtn = b
        b.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)

        let h2 = UITextView(frame:CGRect(x:30,y:(f.height-ht)/2,width:f.width-60, height:ht))
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h2.text = "You are not a member of any community right now. Tap the keypad icon on the footer to find a private community. If you have joined a community but cannot see it here, tap the icon above to reload."
        h2.textColor = Color.primary_dark
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = UIColor.clear
        h2.isUserInteractionEnabled = false
        h2.sizeToFit()
        self.view.addSubview(h2)
        self.emptyLabel = h2
        self.view.bringSubviewToFront(h2)
     
        layoutFooter(dx: 0)
    }
    
    // show splash view
    func showSplash( _ then: @escaping() -> Void ){

        let f = view.frame
        let R = f.width/9
        
        // container
        let v = UIView(frame: UIScreen.main.bounds)
        v.backgroundColor = UIColor.white
        v.alpha = 0.0

        // title
        let h1 = UITextView(frame: CGRect(x: 0, y: 0, width: f.width, height: AppFontSize.H1+20))
        h1.textAlignment = .center
        h1.font = UIFont(name: FontName.icon, size: AppFontSize.H1)
        h1.textColor = Color.black
        h1.backgroundColor = UIColor.clear
        h1.text = APP_NAME
        h1.isUserInteractionEnabled = false
        h1.center.y = v.center.y - 11
        v.addSubview(h1)
            
        // bounce
        let frame = CGRect( x: 0, y: 0, width: R, height: R )
        let widget = NVActivityIndicatorView(frame: frame, type: .ballPulseSync , color: Color.black, padding: 0)
        v.addSubview(widget)
        v.bringSubviewToFront(widget)
        widget.center.x = v.center.x
        widget.center.y = h1.center.y - R/2 - 15
        widget.startAnimating()
        self.blurWidget = widget

        // mount
        view.addSubview(v)
        self.blurView = v

        // show view
        func show(){ self.blurView?.alpha = 1.0 }
        runAnimation( with: show, for: 0.05 ){ then() }

    }
    
    // hide splash view
    func hideSplash( _ then: @escaping() -> Void ){
        func show(){ self.blurView?.alpha = 0.0 }
        runAnimation( with: show, for: 0.20 ){
            self.blurWidget?.stopAnimating()
            self.blurWidget?.removeFromSuperview()
            self.blurWidget = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
            then()
        }
    }
    
    // place timeout indicator
    func placeIndicator(_ str: String ){
        
        if self.awaitView != nil { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: str)
        view.addSubview(pv)
        self.awaitView = pv

        //max duration is six seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0 ) { [weak self] in
            self?.hideIndicator()
        }
    }
    
    // hide indicator function
    func hideIndicator(){
        awaitView?.stop()
        func hide() { self.awaitView?.alpha = 0.0 }
        runAnimation( with: hide, for: 0.25 ){
            self.awaitView?.removeFromSuperview()
            self.awaitView = nil
        }
    }

}





//MARK:- gesture

extension HomeController {
    
    func addGestureResponders(){

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .right
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .right:
                onSwipeRight()
            case .left:
                onSwipeLeft()
            default:
                break
            }
        }
    }
}



//MARK:- top level event listeners
    
extension HomeController {
    
    //@Use: when home page should refresh, refresh home page, show side shelf view then hide it after delay
    @objc func refreshTopLevelNewsFeed(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.reload(){ return }
            let lives = ClubList.shared.whereAmILive()
            if lives.count > 0 {
                self?.showActiveView(on: lives[0])
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                self?.onSwipeRight()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                    self?.onSwipeLeft()
                }
            }
        }
    }
    
    //@Use: when join room, show bottom active room view toast. else remove it
    @objc func didJoinOrLeaveRoom(_ notification: NSNotification){
        guard let id = decodePayload(notification) as? String else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            guard let self = self else { return }
            ClubList.shared.getClub(at: id){club in
                guard let club = club else {
                    self.hideActiveView()
                    return
                }
                if club.iamLiveHere() {
                    if AgoraClient.shared.inChannel() {
                        self.showActiveView(on: club)
                    } else {
                        ToastWarn(title: "Oh no!", body: "We can't establish a connection right now. Please restart the app and try again.")
                        self.hideActiveView()
                    }
                } else {
                    self.hideActiveView()
                }
            }
        }
    }

    /*
     @use: observe for events:
        - fore/background
        - keyboard
        - db events
    */
    func observeAppEvents(){
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        // swipe + tap
        let _ = self.tappable(with: #selector(didTapScreen))

        // listen for app foreground/background state
        observeAppForegroundState(
            appMovedToForeground: #selector(appMovedToForeground),
            appMovedToBackground: #selector(appMovedToBackground)
        )
        
        // listen for push notification from invite to join
        listenForLiveInviteFromPushAwake( on: self, for: #selector(onInviteToLiveEvent) )
    }

    /*
     @use: when user takes acreenshot
    */
    @objc func screenshotTaken(){ return }
    
    /*
     @use: on invited to live event, show modal, if agree join as guest
    */
    @objc func onInviteToLiveEvent(_ notification: NSNotification){
        return
    }
    
    /*
     @use: when app move to foreground,
           load streaming if any.
    */
    @objc func appMovedToForeground(){
        self.appIsForeGround = true
    }

    @objc func appMovedToBackground(){
        self.appIsForeGround  = false
    }
    
    @objc func didTapScreen(){
        SwiftEntryKit.dismiss()
    }
    
    // Enable detection of shake motion
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    }
}
