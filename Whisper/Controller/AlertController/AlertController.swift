//
//  AlertController.swift
//  byte
//
//  Created by Xiao Ling on 12/8/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


enum AlertCellKind {
    case pad
    case follow
    case systemMessage
}

private let BioFontSize = AppFontSize.footer


/*
 @Use: renders my groups
*/
class AlertController: UIViewController {

    // main child view
    var tableView: UITableView?
    var name: String = ""
    var isHome: Bool = false
    
    // style
    var pad_top: CGFloat = 20
    var headerHeight: CGFloat = 80
    var statusHeight : CGFloat = 10.0

    // databasource + delegate
    var user: User?
    var dataSource : [(AlertCellKind,AlertBlob?)] = []

    // pull to refresh
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {

        super.viewDidLoad()
        view.backgroundColor = Color.white
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }        
    }
    
    /*
     @use: call this to load data
    */
    func config( isHome: Bool ){
        self.isHome = isHome
        layout( isHome: false )
        addGestureResponders()
        refresh()
    }
        
    
    func refresh(){
        var res  :  [(AlertCellKind,AlertBlob?)] = [(.pad,nil)]
        let tail :  [(AlertCellKind,AlertBlob?)] = UserAuthed.shared.fetchAlerts().map{ (.follow,$0) }
        res.append(contentsOf:tail)
        self.dataSource = res
        tableView?.reloadData()
        UserAuthed.shared.didSeeAlerts()
    }
    
}



//MARK: - responders

extension AlertController: AlertCellDelegate, AppHeaderDelegate {

    func onHandleDismiss() {
        AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
    }
    

    func onTapProfile(at user: User?) {
        guard let user = user else { return }
        goToProfile(user)
    }
    
    func onFollow(at user: User?) {
        guard let user = user else { return }
        if UserAuthed.shared.iAmFollowing(at: user.uuid) {
            UserAuthed.shared.unfollow(user)
        } else {
            UserAuthed.shared.follow(user)
        }
    }
    
    private func onJoinGroup( at alert: AlertBlob? ){

        guard let alert = alert else { return }
        ClubList.shared.getClub(at: alert.meta){ club in
            guard let club = club else {
                return ToastSuccess(title: "Oh no!", body: "We can't find this channel!")
            }
            club.join(_HARD_UID: UserAuthed.shared.uuid, with: .levelB){ return }
            ToastSuccess(title: "Done!", body: "You will see the channel in your home page in a second")
            postRefreshClubPage(at:club.uuid)
        }
    }
    
    // tap alert btn, respond
    func onTapBtn(from alert: AlertBlob? ){
        
        guard let alert = alert else { return }
        
        switch alert.kind {

        case .follow:
            onFollow(at: alert.source)

        case .alertMe:
            UserAuthed.shared.follow(alert.source)

        case .inviteToGroup:
            onJoinGroup(at: alert)
            
        case .joinGroup:
            break
            
        default:
            break;
        }
        
    }

    private func goToProfile( _ user: User ){
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
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
                onHandleDismiss()
            default:
                break
            }
        }
    }

    
}

//MARK:- table-




extension AlertController: UITableViewDataSource, UITableViewDelegate  {
    
    
    func layout( isHome: Bool ){
        
        let f   = view.frame
        var dy = statusHeight
        
        let h = AppHeader(frame: CGRect( x: 0, y: dy, width: f.width, height: headerHeight ))
        h.config( showSideButtons: true, left: "", right: "", title: "Activity", mode: .light )
        h.backgroundColor = UIColor.clear
        h.delegate = self
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
        
        dy += headerHeight
        let ht = f.height - dy

        let table: UITableView = UITableView(frame: CGRect(x:0,y:dy,width:f.width,height:ht))
        table.register(PadCell.self     , forCellReuseIdentifier: PadCell.identifier )
        table.register(UserRowCell.self , forCellReuseIdentifier: UserRowCell.identifier)
        table.register(AlertCell.self   , forCellReuseIdentifier: AlertCell.identifier)
        table.register(TextCell.self    , forCellReuseIdentifier: TextCell.identifier)

        // mount
        self.tableView = table
        self.view.addSubview(table)
        
        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.backgroundColor = UIColor.clear
        self.tableView?.separatorStyle = .none
        
        // PTR
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }

        refreshControl.addTarget(self, action: #selector(ptr(_:)), for: .valueChanged)
        refreshControl.alpha = 0.0
    }
    
    @objc private func ptr(_ sender: Any) {
        refresh()
        self.refreshControl.endRefreshing()
    }
    
    
    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let (kind,msg) = dataSource[indexPath.row]

        switch kind {
        case .pad:
            return 20
        case .systemMessage:
            return computeLabelHt("")
        case .follow:
            return computeLabelHt( msg?.text ?? "" )
        }

    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let (kind, alert) = dataSource[indexPath.row]

        switch kind {

        case .pad:

            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: UIColor.clear)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell

        case .systemMessage:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as! TextCell
            cell.config(with: "", font: UIFont(name: FontName.regular, size: BioFontSize)!)
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .left
            cell.backgroundColor = UIColor.clear
            return cell


        case .follow:

            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            cell.config(with: alert )
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = .none
            cell.delegate = self
            return cell
        }
    }
    
    private func computeLabelHt( _ str: String = "" ) -> CGFloat {
        
        if str ==  "" {
            return 2.0
        } else {
            let f  = view.frame
            let _h = BioFontSize
            let v  = UILabel(frame: CGRect(x:0,y:0, width:f.width, height:_h))
            v.text = str
            v.textAlignment = .left
            v.body2()
            let num = v.maxNumberOfLines + 1
            return CGFloat(num) * _h + 30
        }
    }

}

