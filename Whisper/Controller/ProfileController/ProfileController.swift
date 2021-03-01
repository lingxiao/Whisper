//
//  ProfileController.swift
//  byte
//
//  Created by Xiao Ling on 12/7/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit


enum ProfileDataItem {
    case none
    case pad
    case hero
    case bio
    case follow
    case title
    case follower
}

private let ROOT : [(ProfileDataItem,User?)] = [(.pad,nil),(.hero,nil),(.bio,nil),(.follow,nil),(.pad,nil),(.title,nil)]

/*
 @Use: renders my groups
*/
class ProfileController: UIViewController {

    // main child view
    var header: AppHeader?
    var tableView: UITableView?
    
    // style
    var pad_top: CGFloat = 20
    var headerHeight: CGFloat = 60
    var statusHeight : CGFloat = 10.0

    // databasource + delegate
    var user: User?
    var dataSource: [(ProfileDataItem,User?)] = ROOT

    // pull to refresh
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.primary
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
        // swipe to dismiss
        addGestureResponders()
    }
    
    /*
     @use: call this to load data
    */
    func config( with user: User?, isHome: Bool = false ){
        
        self.user = user
        user?.awaitFull()

        layoutHeader( isHome )
        layoutTable( isHome: isHome )
        if let header = self.header {
            tableView?.tableHeaderView = header
        }
        tableView?.reloadData()
        
        // fetch data after user's data has loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.refresh()
        }
    }
    
    func refresh(){

        guard let user = user else { return}
        if WhisperGraph.shared.didBlockMe(this: user) { return }

        user.fetchPeopleISpokeTo(){users in
            var res  : [(ProfileDataItem,User?)] = ROOT
            let tail : [(ProfileDataItem,User?)] = users.map{ (.follower,$0) }
            res.append((.pad,nil))
            res.append(contentsOf: tail)
            res.append(contentsOf: [(.pad,nil),(.pad,nil)])
            self.dataSource = res
            self.tableView?.reloadData()
        }
    }
    
        
}


//MARK: - responders


extension ProfileController: SocialCellProtocol, UserRowCellProtocol, AppHeaderDelegate {

    func onHandleDismiss(){
        AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
    }
    
    private func goToProfile( _ user: User ){
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func handleGetAerts(_ x: UIAlertAction){
        UserAuthed.shared.follow(user)
    }
    
    private func handleNoAlerts(_ x: UIAlertAction) {
        UserAuthed.shared.unfollow(user)
    }
    
    private func handleFlag(_ x: UIAlertAction){
        UserAuthed.shared.flag(user?.uuid)
        ToastSuccess(title: "", body: "Flagged")
    }
    
    private func handleBlock(_ x: UIAlertAction) {
        if WhisperGraph.shared.iDidBlock(this: user){
            WhisperGraph.shared.block(user: user, blocking: false)
            ToastSuccess(title: "", body: "Unblocked")
        } else {
            WhisperGraph.shared.block(user: user, blocking: true)
            ToastSuccess(title: "", body: "Blocked")
        }
    }

    func handleTap(on user: User?) {

        guard let user = user else { return }

        if user.isMe(){
            heavyImpact()
            heavyImpact()
        } else {
            mediumImpact()
            if let curr = self.user {
                if curr.uuid == user.uuid {
                    heavyImpact()
                } else {
                    goToProfile(user)
                }
            } else {
                goToProfile(user)
            }
        }
    }
    
   
    func handleBtn(on user: User?) {
        guard let user = user else { return }
        heavyImpact()
        if UserAuthed.shared.iAmFollowing(at: user.uuid) {
            UserAuthed.shared.unfollow(user)
        } else {
            UserAuthed.shared.follow(user)
        }
    }

    func follow() {
        guard let user = user else { return }

        if user.isMe(){
            let vc = EditProfileController()
            vc.view.frame = UIScreen.main.bounds
            vc.config()
            AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
        } else {
            handleBtn(on: user)
        }
    }
    
    func ig() {

        guard let user = user else { return }

        let Username =  user.instagram
        
        if Username == "" {
            
            ToastSuccess(title: "Not linked", body: "This person has not linked Instagram")
            
        } else {
            
            let application = UIApplication.shared

            if let appURL = URL(string: "instagram://user?username=\(Username)"){
                if application.canOpenURL(appURL) {
                    application.open(appURL)
                } else {
                    // if Instagram app is not installed, open URL inside Safari
                    if let webURL = URL(string: "https://instagram.com/\(Username)"){
                        application.open(webURL)
                    }
                }
            }
        }
    }
    
    func twitter() {

        guard let user = user else { return }

        let Username =  user.twitter
        
        if Username == "" {
            ToastSuccess(title: "Not linked", body: "This person has not linked Twitter")
        } else {
            
            guard let appURL = URL(string: "twitter://user?screen_name=\(Username)") else { return }

            if UIApplication.shared.canOpenURL(appURL as URL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(appURL)
                } else {
                    UIApplication.shared.openURL(appURL)
                }
            } else {
                guard let webURL = URL(string: "https://twitter.com/\(Username)") else { return}
                //redirect to safari because the user doesn't have twitter
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(webURL)
                } else {
                    UIApplication.shared.openURL(webURL)
                }
            }

        }
    }
    
    func linkedin() {
        
        guard let user = user else { return }

        let Username = user.website
        
        if Username == "" {

            ToastSuccess(title: "Not linked", body: "This person has not connected a website")

        } else {
            
            if let url = URL(string: Username){
                UIApplication.shared.open(url)
            }
            
            /*guard let appURL = URL(string: "linkedin://profile/\(Username)") else { return }
            if UIApplication.shared.canOpenURL(appURL as URL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(appURL)
                } else {
                    UIApplication.shared.openURL(appURL)
                }
            } else {
                guard let webURL = URL(string: "https://linkedin.com/in/\(Username)") else { return}
                //redirect to safari because the user doesn't have twitter
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(webURL)
                } else {
                    UIApplication.shared.openURL(webURL)
                }
            }*/
        }
    }
    
    func onBell(){
        
        guard let user = user else { return }

        let str = "Control Notifications"

        if user.isMe() {

            let bod = "How often do you want to receive notifications"
            let optionMenu = UIAlertController(title: "Notification frequency", message: bod, preferredStyle: .actionSheet)
                
            let deleteAction = UIAlertAction(title: "Always"   , style: .default, handler: nil)
            let saveAction   = UIAlertAction(title: "Sometimes", style: .default, handler: nil)
            let cancelAction = UIAlertAction(title: "Cancel"   , style: .cancel )
                
            optionMenu.addAction(deleteAction)
            optionMenu.addAction(saveAction)
            optionMenu.addAction(cancelAction)
                
            self.present(optionMenu, animated: true, completion: nil)

        } else {
            
            let bod = "Receive notification each time \(user.get_H1()) is in a room."
            let optionMenu = UIAlertController(title: str, message: bod, preferredStyle: .actionSheet)
                
            let deleteAction = UIAlertAction(title: "Always", style: .default, handler: self.handleGetAerts)
            let saveAction   = UIAlertAction(title: "Never" , style: .default, handler: self.handleNoAlerts)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel )
                
            optionMenu.addAction(deleteAction)
            optionMenu.addAction(saveAction)
            optionMenu.addAction(cancelAction)
                
            self.present(optionMenu, animated: true, completion: nil)
            
        }
    }
    
    func onDots(){
        
        guard let user = user else { return }
        
        if user.isMe() {

            let vc = EditProfileController()
            vc.view.frame = UIScreen.main.bounds
            vc.config()
            AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
            
        } else {
        
            let header = "Flag or block \(user.get_H1())"
            let bod = ""
            let optionMenu = UIAlertController(title: header, message: bod, preferredStyle: .actionSheet)
            
            let str = WhisperGraph.shared.iDidBlock(this: user) ? "Unblock" : "Block"
                
            let flagAction   = UIAlertAction(title: "Flag" , style: .default, handler:self.handleFlag(_:))
            let blockAction  = UIAlertAction(title: str, style: .default, handler:self.handleBlock(_:))
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            optionMenu.addAction(flagAction)
            optionMenu.addAction(blockAction)
            optionMenu.addAction(cancelAction)
                
            self.present(optionMenu, animated: true, completion: nil)
                
        }
        
    }

}




//MARK:- gesture

extension ProfileController {
    
    func dismissSelf(){
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
    func addGestureResponders(){
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
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
                dismissSelf()
            case .down:
                break;
            case .left:
                break;
            case .up:
                break;
            default:
                break
            }
        }
    }
}


