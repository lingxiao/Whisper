//
//  InviteUserController.swift
//  byte
//
//  Created by Xiao Ling on 11/1/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

protocol InviteUserProtocol {
    func didSelect( users: [User] ) -> (Bool,String)
}

class InviteUserController: UIViewController {
    
    // picker delegates
    var domain: String = ""
    var delegate: InviteUserProtocol? 
        
    // databasource
    var dataSource: [User] = []
    var filteredDataSource: [User] = []
    var selected  : [User] = []
    var isSearching: Bool = false
    
    var selectedGroups: [User] = []
    
    // style
    var pad_top: CGFloat = 20
    var headerHeight: CGFloat = 60
    var searchHeight: CGFloat = 40
    var buttonHeight : CGFloat = 50
    var offsetBottom: CGFloat = 0
    var statusHeight : CGFloat = 10.0

    // mode
    var header: String = ""
    var hasSearch: Bool = true
    var userActionBtn: String?
    
    //[BEGIN] child view
    var appNavHeader: AppHeader?
    var tableView : UITableView?
    var inputTextField: PaddedTextField?
    var inviteBtn: TinderTextButton?
    //[END] child view
    
    var lightStatusBar: Bool = false
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.lightStatusBar ? .lightContent : .default
    }
    
    // search
    var searchController = UISearchController(searchResultsController: nil)
    var isSearchBarEmpty: Bool { return searchController.searchBar.text?.isEmpty ?? true }
    var isFiltering: Bool { return searchController.isActive && !isSearchBarEmpty }

    // color scheeme
    var mode : StyleMode = .dark
    var base : UIColor   = Color.primary
    var dark : UIColor   = Color.primary_dark
    var accent: UIColor  = Color.redDark
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationCapturesStatusBarAppearance = true
        view.backgroundColor = Color.primary
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.lightStatusBar = true
        UIView.animate(withDuration: 0.3) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    /*
     @use: set header name and load data
    */
    public func config(
        data: [User] = [],
        title: String = "Invite",
        domain: String = "",
        buttonStr: String = "Invite",
        showHeader: Bool = true
    ){
        
        // set view props and nav
        self.header     = title
        self.domain     = domain
        self.userActionBtn = "Invite"

        // init data
        self.dataSource = data

        // set up views
        if showHeader{
            placeNavHeader()
            addGestureResponders()
        }

        setUpSearch(showHeader)
        setUpTableView(showHeader)
        placeInviteBtn( buttonStr )

    }
    
    //MARK:- gesture responder

    func addGestureResponders(){        
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
            default:
                break
            }
        }
    }
    

}
