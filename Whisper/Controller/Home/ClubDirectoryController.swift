//
//  ClubDirectoryController.swift
//  byte
//
//  Created by Xiao Ling on 12/11/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit



//MARK:-

private let BioFontSize = AppFontSize.footer

enum DirectoryCellKind {
    case pad
    case bot_pad
    case homeClub
    case widgets
    case newClub
    case liveClub
    case notLiveClub
    case footer
}

protocol ClubDirectoryDelegate {
    func showClub( at club: Club? ) -> Void
    func shareNumber(from org: OrgModel?) -> Void
    func onCreateNewCohort(from org: OrgModel?) -> Void
    func onCreateEmphRoom( from org: OrgModel?, name: String) -> Void
}

typealias DirectoryDataSource = [(DirectoryCellKind, [Club?])]

private let bkColor = UIColor.clear 

/*
 @Use: renders my groups
*/
class ClubDirectoryController: UIViewController {
        
    // delegate + parent
    var parentVC: HomeController?
    var delegate: ClubDirectoryDelegate?

    // main child view
    var header: HomeHeader?
    var tableView: UITableView?
    var header_height: CGFloat = 90.0
    
    // databasource
    var org: OrgModel? = nil
    var clubs: [Club]  = []
    var dataSource : DirectoryDataSource = [(.pad,[])]
    
    // pull to refresh
    var refreshControl = UIRefreshControl()
    var lastRefresh: (String,Int) = ("",ThePast())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        primaryGradient(on: self.view)
    }
    
    /*
     @use: call this to load data
    */
    func config( with org: OrgModel?, clubs: [Club],  parentVC: HomeController? ){
        self.parentVC = parentVC
        self.org   = org
        self.clubs = clubs
        layoutHeaderA()
        setUpTableView()
        if let header = self.header {
            tableView?.tableHeaderView = header
        }
        refresh()
        listenRefreshClubPage(on: self, for: #selector(goReloadPage))
    }
    
    
    @objc func goReloadPage( _ notification: NSNotification){

        let ( prev_id, prev_t ) = self.lastRefresh
        let id = decodePayload(notification)
        
        if prev_id == id && now() - prev_t  < 1 {
            return
        } else {
            var inOrg: Bool = false
            if let org = org {
                if let id = id {
                    inOrg = org.clubIDs.contains(id)
                }
            }
            if (clubs.map{ $0.uuid }.contains(id) || id == "ALL" || inOrg) {
                self.lastRefresh = (id ?? "", now() + 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                    self?.refresh()
                }
            }
        }
    }

    func refresh(){
        
        let me = UserList.shared.yieldMyself()
        if let org = self.org {
            self.clubs = ClubList.shared.fetchClubsFor(school: org)
        }
        
        var res : DirectoryDataSource = [(.pad,[]),(.pad,[])]

        let home = clubs.filter{ $0.type == .home }
        
        // clubs that are just created or joined by me
        let head = clubs.filter{ $0.iJustCreated() || $0.iJustJoined() }
            .filter{ !home.contains($0) }
        
        // clubs that are live
        let iLIVE  = clubs.filter{ $0.someoneIsLiveHere() }
            .filter{ !home.contains($0) }
            .filter{ !head.contains($0) }
        
        // clubs that I admin
        var tail = clubs.filter{ $0.isAdmin(me) }
            .filter{ !home.contains($0) }
            .filter{ !iLIVE.contains($0) }
            .filter{ !head.contains($0) }

        // clubs that I can speak in
        let rest = clubs.filter{ $0.isAdminOrSpeaker(me) }
            .filter{ !home.contains($0) }
            .filter{ !tail.contains($0) && !iLIVE.contains($0) }
            .filter{ !head.contains($0) }
        
        // all the other clubs 
        let open = clubs
            .filter{ !rest.contains($0) }
            .filter{ !home.contains($0) }
            .filter{ !tail.contains($0) && !iLIVE.contains($0) }
            .filter{ !head.contains($0) }
        
        tail.append(contentsOf: rest)
        tail.append(contentsOf: open)
        
        if home.count > 0 {
            let ys = home.map{ [$0]}
            let xs : DirectoryDataSource = ys.map{ (.homeClub,$0) }
            res.append(contentsOf: xs)
        }
        
        res.append(contentsOf: [(.widgets,[])])

        if head.count > 0 {
            let ys = head.map{ [$0]}
            let xs : DirectoryDataSource = ys.map{ (.newClub,$0) }
            res.append(contentsOf: xs)
        }

        if iLIVE.count > 0 {
            let sorted_live = iLIVE.sorted{ $0.isGreaterThan( $1 ) }
            let ys = sorted_live.map{ [$0]}
            let xs : DirectoryDataSource = ys.map{ ( .liveClub, $0) }
            res.append(contentsOf: xs)
        }

        if tail.count > 0 {
            let xs : DirectoryDataSource = to2DArray(tail).map{ ( .notLiveClub,$0) }
            res.append(contentsOf: xs)
        }
        
        res.append( (.bot_pad,[]) )

        self.dataSource = res
        tableView?.reloadData()
        header?.setLabel(to: self.org?.get_H1() ?? APP_NAME )
        
    }
        
}

//MARK:- responders

extension ClubDirectoryController : ClubWidgetCellDelegate {

    func onTap( at kind: ClubWidgetCellKind ){
        switch kind {
        case .newRoom:
            delegate?.onCreateNewCohort(from: self.org)
        case .shareNumber:
            delegate?.shareNumber(from:self.org)
        case .calendar:
            guard let org = org else { return }
            let vc = CalendarController()
            vc.view.frame = UIScreen.main.bounds
            vc.config(with: org)
            AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
        }
    }

}

extension ClubDirectoryController: ClubCohortCellDelegate
                                   , ClubHomeDirCellDelegate
                                   , HeaderH2CellDelegate {

    func didTapH2Btn() {
        let name = self.org?.get_H1() ?? "this community"
        let str = "Hidden channels are private spaces hosted by members of \(name), they are currently invisible to you. To start a new channels, tap the button on the top right of this screen."
        ToastBlurb(title: "Hidden channels", body: str)
    }
    
    func onTapClub( at club: Club? ){
        heavyImpact()
        if let club = club {
            delegate?.showClub(at:club)
        } else {
            delegate?.onCreateNewCohort(from: self.org)
        }
    }

    func onTapHomeClub( at club: Club? ){
        heavyImpact()
        delegate?.showClub(at:club)
    }

    func onTapIcon( at club: Club? ){
        return
    }
    
    func onTap(user:User?){
        guard let user = user else { return }
        if user.isMe() {
            heavyImpact()
            heavyImpact()
        } else {
            heavyImpact()
            let vc = ProfileController()
            vc.view.frame = UIScreen.main.bounds
            vc.config( with: user, isHome: true )
            AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ClubDirectoryController : HomeHeaderDelegate {

    func onProfile() {
        let v = EditClubController()
        v.view.frame = UIScreen.main.bounds
        v.config(with: nil, room: nil, org: self.org )
        AuthDelegate.shared.home?.navigationController?.pushViewController(v, animated: true)
    }
    
    func onBell() {
        return
    }
    
    func onNewGroup() {
        delegate?.onCreateNewCohort(from: self.org)
    }
}


//MARK:- view

extension ClubDirectoryController: UITableViewDataSource, UITableViewDelegate {

    private func layoutHeaderA(){
        let f = view.frame
        let rect = CGRect(x:0,y:0,width:f.width,height:header_height)
        let header = HomeHeader(frame: rect)
        header.config( simple: true, title: self.org?.name ?? "" )
        view.addSubview(header)
        header.backgroundColor = bkColor
        header.delegate = self
        self.header = header
    }
    
    
    // layout table
    private func setUpTableView(){

        let f = view.frame
        let table: UITableView = UITableView(frame: CGRect(x:0,y:0,width:f.width,height:f.height))
        
        // register cells
        table.register(PadCell.self          , forCellReuseIdentifier: PadCell.identifier )
        table.register(HeaderH2Cell.self     , forCellReuseIdentifier: HeaderH2Cell.identifier)
        table.register(ClubHomeDirCell.self  , forCellReuseIdentifier: ClubHomeDirCell.identifier)
        table.register(ClubCohortCell.self   , forCellReuseIdentifier: ClubCohortCell.identifier)
        table.register(ClubWidgetCell.self, forCellReuseIdentifier: ClubWidgetCell.identifier)
        
        // mount
        self.tableView = table
        self.view.addSubview(table)
        
        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.backgroundColor = bkColor
        self.tableView?.separatorStyle = .none

        // PTR
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }

        refreshControl.addTarget(self, action: #selector(ptr(_:)), for: .valueChanged)
        refreshControl.alpha = 0

    }
    
    @objc private func ptr(_ sender: Any) {
        heavyImpact()
        refresh()
        self.refreshControl.endRefreshing()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        if let headerView = self.tableView?.tableHeaderView as? HomeHeader {
            headerView.scrollViewDidScroll(scrollView: scrollView)
        }
    }

    
    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let ( kind, clubs ) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return 5.0
        case .bot_pad:
            return computeTabBarHeight() + 30
        case .footer:
            return AppFontSize.body+20
        case .homeClub:
            return clubs.count > 0 ?  ClubHomeDirCell.Height(type:.home) : 1
        case .newClub:
            if clubs.count == 0 {
                return 1.0
            } else {
                if let club = clubs[0] {
                    if club.someoneIsLiveHere() {
                        return ClubHomeDirCell.Height(type:.live)
                    } else {
                        return ClubHomeDirCell.Height(type:.newItem)
                    }
                } else {
                    return 1.0
                }
            }
        case .liveClub:
            return clubs.count > 0 ?  ClubHomeDirCell.Height(type:.live) : 1
        case .notLiveClub:
            return clubs.count > 0 ? ClubCohortCell.Height() : 1
        case .widgets:
            return ClubWidgetCell.Height()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let (kind,clubs) = dataSource[indexPath.row]
        
        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell

        case .bot_pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell

        case .footer:
            let num = 0
            let pp = Double(num).formatPoints()
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH2Cell", for: indexPath) as! HeaderH2Cell
            cell.config(with: "\(pp) hidden" )
            cell.delegate = self
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        
        case .homeClub:
            return pickClubCell(at: indexPath, from: tableView, with: clubs, type: .home)

        case .newClub:
            if let club = clubs[0] {
                return pickClubCell(at: indexPath, from: tableView, with: clubs, type: club.someoneIsLiveHere() ?  .live : .newItem)
            } else {
                return pickClubCell(at: indexPath, from: tableView, with: [], type: .newItem)
            }

        case .liveClub:
            return pickClubCell(at: indexPath, from: tableView, with: clubs, type: .live)

        case .notLiveClub:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClubCohortCell", for: indexPath) as! ClubCohortCell
            cell.config(with: clubs)
            cell.selectionStyle = .none
            cell.delegate = self
            cell.backgroundColor = bkColor
            return cell
            
        case .widgets:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClubWidgetCell", for: indexPath) as! ClubWidgetCell
            cell.config(with: [.calendar,.shareNumber], for: self.org)
            cell.selectionStyle = .none
            cell.delegate = self
            cell.backgroundColor = bkColor
            return cell

        }
    }
    
    private func pickClubCell(
        at indexPath: IndexPath,
        from tableView: UITableView,
        with clubs: [Club?],
        type: ClubHomeDirCellType
    ) -> UITableViewCell {
        if clubs.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClubHomeDirCell", for: indexPath) as! ClubHomeDirCell
            cell.config(with: clubs[0], at: self.org, type: type)
            cell.delegate = self
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        }
    }

}



//MARK:- utils-


private func to2DArray( _ reduced: [Club?] ) -> [[Club?]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/2) + 1
    
    while num > 0 {
        patternArray.append([0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    return res
}
