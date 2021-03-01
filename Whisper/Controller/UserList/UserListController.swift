//
//  UserListController.swift
//  byte
//
//  Created by Xiao Ling on 7/30/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


/*
 @Use: renders my groups
*/
class UserListController: UIViewController {

    // main child view
    var appNavHeader : AppHeader?
    var tableView: UITableView?
    var name: String = ""
    var buttonRight: String?
    
    // style
    var pad_top: CGFloat = 20
    var headerHeight: CGFloat = 80
    
    // databasource
    var dataSource : [(User)] = []
    var _data_source_off_set : Int = 1
    
    // pull to refresh
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            pad_top = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            pad_top = UIApplication.shared.statusBarFrame.height
        }
    }
    
    /*
     @use: call this to load data
    */
    func config(
          title: String
        , with users: [(User)]
        , for message: String = ""
        , buttonRight: String? = nil
    ){
        self.dataSource = users
        self.name = title
        view.backgroundColor = Color.primary

        layoutHeader()
        setUpTableView()
        tableView?.reloadData()
        addGestureResponders()
    }
        
    @objc func refresh(_ sender: AnyObject) {
        refreshControl.endRefreshing()
    }
    
    /*
        @Use: show blank view
    */
    func setupBlankView( for header: String, with msg: String ){
        
        let f = view.frame
        let blank = BlankListView(frame:CGRect(
              x: 0
            , y: 0
            , width: f.width
            , height: f.height
        ))
        
        blank.config( header: header, msg: msg )
        view.addSubview(blank)
    }

}

//MARK:- events

extension UserListController : AppHeaderDelegate, UserRowCellProtocol {

    func handleTap(on user: User?) {
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func handleBtn(on user: User?) {
        if UserAuthed.shared.iAmFollowing(at: user?.uuid){
            UserAuthed.shared.unfollow(user)
        } else {
            UserAuthed.shared.follow(user)
        }
    }
    

    func onHandleDismiss() {
        dismissSelf()
    }
    
}


//MARK:- gesture

extension UserListController {
    
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


