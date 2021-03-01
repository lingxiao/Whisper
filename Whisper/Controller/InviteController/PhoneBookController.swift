//
//  PhoneBookController.swift
//  byte
//
//  Created by Xiao Ling on 2/15/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit

protocol PhoneBookControllerProtocol {
    func didSelect( users: [PhoneContact] ) -> Void
}

class PhoneBookController: UIViewController {
    
    // picker delegates
    var delegate: PhoneBookControllerProtocol?
        
    // databasource
    var dataSource: [PhoneContact] = []
    var filteredDataSource: [PhoneContact] = []
    var selected  : [PhoneContact] = []
    var isSearching: Bool = false
    
    var selectedGroups: [PhoneContact] = []
    
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
    var userActionBtn: String = "Invite"
    
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
    public func config( showHeader: Bool = false ){
        if showHeader {
            addGestureResponders()
        }
        setUpSearch(showHeader)
        setup(showHeader)
        placeInviteBtn("Invite")
        reload()
    }
    
    private func reload(){
        // load data
        permitAddressBook(){(succ,msg) in
            if succ {
                DispatchQueue.main.async {
                    PhoneContacts.shared.await()
                    self.dataSource = PhoneContacts.shared.addressBook.filter{ $0.get_H1() != "" }
                    self.tableView?.reloadData()
                }
            } else {
                ToastSuccess(title: "Oh no!", body: "We do not have permission to access your contacts")
            }
        }
    }


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

//MARK:- events

extension PhoneBookController: AppHeaderDelegate, ContactBookCellDelegate {

    func onHandleDismiss() {
        dismissSelf()
    }
    
    func handleTap(on user: PhoneContact?) {

        mediumImpact()
        guard let user = user else { return }
        
        // insert or remove user from selected
        if self.selected.contains( user ) {
            let small = self.selected.filter{ $0 != user }
            self.selected = small
        } else {
            self.selected.append( user )
        }
        
        // update row
        if self.isSearching {
            if let idx = filteredDataSource.firstIndex(of: user) {
                let index = IndexPath(row: idx, section: 0)
                tableView?.reloadRows(at: [index], with: .automatic)
            }
        } else {
            if let idx = dataSource.firstIndex(of: user) {
                let index = IndexPath(row: idx, section: 0)
                tableView?.reloadRows(at: [index], with: .automatic)
            }
        }
    }
    
    func handleBtn(on user: User?) {
        return
    }

    
    @objc func onPressCenterBtn(_ button: TinderButton ){
        delegate?.didSelect(users: self.selected)
    }
    
    func dismissSelf(){
        self.inputTextField?.resignFirstResponder()
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
}


//MARK:- layout table-

extension PhoneBookController: UITableViewDataSource, UITableViewDelegate {
    
    // set up table
    func setup( _ showHeader : Bool ){

        let f = view.frame
        let dy = showHeader
            ? headerHeight + searchHeight + pad_top + statusHeight
            : searchHeight + pad_top

        let table: UITableView = UITableView(frame: CGRect(
              x: 0
            , y: dy
            , width: f.width
            , height: f.height - dy
        ))

        // register cells
        table.register(PadCell.self        , forCellReuseIdentifier: PadCell.identifier )
        table.register(HeaderH1Cell.self   , forCellReuseIdentifier: HeaderH1Cell.identifier )
        table.register(ContactBookCell.self, forCellReuseIdentifier: ContactBookCell.identifier)

        // mount
        self.tableView = table
        self.view.addSubview(table)

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = true
        self.tableView?.backgroundColor = UIColor.clear
        self.tableView?.separatorStyle = .none

    }


    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isSearching){
            return filteredDataSource.count
        } else {
            return self.dataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let data = isSearching ? filteredDataSource[row] : dataSource[row]        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactBookCell", for: indexPath) as! ContactBookCell
        cell.config(with: data)
        cell.backgroundColor = Color.primary
        cell.delegate = self
        cell.highlight(selected.contains(data))
        return cell

    }
      
}

