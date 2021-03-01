//
//  OnboardCommunController.swift
//  byte
//
//  Created by Xiao Ling on 2/21/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- datatypes

enum CommuneCellKind {
    case pad
    case padEnd
    case banner
    case hero
    case headerA
    case tags
}

typealias CommuneData = [(CommuneCellKind,String,[TagModel])]

private let bkColor = UIColor.clear

//MARK:- class


class OnboardCommunController: UIViewController, TagCellDelegate {
    
    // style + view
    var headerHeight: CGFloat = 80
    var statusHeight: CGFloat = 20
    var tableView: UITableView?
    let refreshControl = UIRefreshControl()
    var awaitView: AwaitWidget?

    // data
    var page: Int = 0
    var club: Club?
    var dataSource: CommuneData = []
    var selected: [TagModel] = []
    
    override func viewDidLoad() {
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        super.viewDidLoad()
        primaryGradient(on: self.view)
    }

    func config( with club: Club? ){
        self.club = club
        layout()
        reload()
    }
    
    /*
     @use: load
        - gradation year
        - major
        - clubs you were part of
     */
    func reload(){

        var res : CommuneData = [(.pad,"",[]),(.banner,"",[]),(.pad,"",[]),(.hero,"",[])]
        let tags = ClubList.shared.fetchTags(for: club?.getOrg())
        
        if tags.count > 0 {
            
            let grads     = tags.filter{ $0.meta.contains( .grad_year) }.sorted{ $0.get_H3() > $1.get_H3() }
            let sports    = tags.filter{ $0.meta.contains( .sports)    }
            let sororites = tags.filter{ $0.meta.contains( .sorority)  }
            let frats     = tags.filter{ $0.meta.contains( .fraternity)}
            
            if grads.count > 0 {
                var xs : CommuneData = [(.headerA,pp_meta(.grad_year),[]),(.pad,"",[])]
                let ys : CommuneData = to2DArray(grads).map{ (.tags, "", $0 ) }
                xs.append(contentsOf:  ys)
                xs.append((.pad,"",[]))
                res.append(contentsOf: xs)
            }
            
            if sports.count > 0 {
                var xs : CommuneData = [(.headerA,pp_meta(.sports),[]),(.pad,"",[])]
                let ys : CommuneData = to2DArray(sports).map{ (.tags, "", $0 ) }
                xs.append(contentsOf:  ys)
                xs.append((.pad,"",[]))
                res.append(contentsOf: xs)
            }

            if sororites.count > 0 {
                var xs : CommuneData = [(.headerA,pp_meta(.sorority),[]),(.pad,"",[])]
                let ys : CommuneData = to2DArray(sororites).map{ (.tags, "", $0 ) }
                xs.append(contentsOf:  ys)
                res.append(contentsOf: xs)
            }

            if frats.count > 0 {
                var xs : CommuneData = [(.headerA,pp_meta(.fraternity),[]),(.pad,"",[])]
                let ys : CommuneData = to2DArray(frats).map{ (.tags, "", $0 ) }
                xs.append(contentsOf:  ys)
                res.append(contentsOf: xs)
            }

        }

        res.append((.padEnd,"",[]))
        self.dataSource = res
        tableView?.reloadData()
    }
    
    /*
     @use: - Subscribe to clubs that are tagged by selected tags
           - ping users of all clubs to for the new audience
     */
    @objc func handleTapJoin(_ button: TinderButton ){

        if selected.count == 0 {

            ToastSuccess(title: "Please select at least one tag", body: "")

        } else {

            let clubs = ClubList.shared.fetchClubsFor(school: self.club?.getOrg())

            if clubs.count > 0 {
                
                var should_tag : [Club] = []
                for tag in selected {
                    let tagged_clubs = clubs.filter{ tag.taggedThis(club: $0) }
                    for tc in tagged_clubs {
                        if should_tag.contains(tc) == false {
                            should_tag.append(tc)
                        }
                    }
                }
                
                if should_tag.count > 0 {
                    
                    let chanStr = should_tag.count > 1 ? "channels" : "channel"
                    ToastSuccess(title: "We found \(should_tag.count) \(chanStr) for you", body: "Give us a few seconds to sync your interests")
                        
                    // place timeout indicator
                    placeIndicator()
                    
                    // join the relevant clubs at speaker level
                    for club in should_tag {
                        club.join(with: .levelB){ return }
                    }                    
                    
                    // send push notification to all club members that I have joined
                    var members : [User] = []
                    for club in should_tag {
                        let mems = club.getMembers()
                        for user in mems {
                            if members.contains(user) == false {
                                members.append(user)
                            }
                        }
                    }
                    ClubList.shared.sendPushNotificationToSponsor(to: members.map{$0.uuid})

                    // force timeout to await for the notification to send
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0 ) { [weak self] in
                        self?.hideIndicator()
                        ToastSuccess(title: "All set!", body: "You can tap any channel on this page to join the chat room.")
                        AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)                        
                    }
                    
                } else {
                    
                    ToastSuccess(title: "All set!", body: "You can tap any channel on this page to join the chat room.")
                    AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
                }

            } else {

                ToastSuccess(title: "All set!", body: "You can tap any channel on this page to join the chat room.")
                AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
            }

        }
    }
    
    // when tag selected, add to list
    func didTap(on tag:TagModel?){
        guard let tag = tag else { return }
        if ( selected.contains(tag) ) {
            let sm = selected.filter{ $0 != tag }
            self.selected = sm
            reload()
        } else {
            selected.append(tag)
            reload()
        }
        
    }
    
}

//MARK:- view

extension OnboardCommunController: UITableViewDataSource, UITableViewDelegate {

    func layout(){
        
        let f = view.frame

        // table
        let table = UITableView(frame:CGRect(x:0,y:statusHeight,width:f.width,height:f.height-statusHeight))
        self.view.addSubview(table)
        self.tableView = table
            
        // register cells
        tableView?.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        tableView?.register(HeaderH3Cell.self, forCellReuseIdentifier: HeaderH3Cell.identifier )
        tableView?.register(BannerCell.self, forCellReuseIdentifier: BannerCell.identifier )
        tableView?.register(OnboardHeroCell.self, forCellReuseIdentifier: OnboardHeroCell.identifier )
        tableView?.register(TagCell.self, forCellReuseIdentifier: TagCell.identifier )

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.separatorStyle = .none
        tableView?.backgroundColor =  bkColor
        
        // PTR
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(ptr(_:)), for: .valueChanged)
        refreshControl.alpha = 0.0
        
        // btn
        let btn = TinderTextButton()
        let R : CGFloat = 40.0
        btn.frame = CGRect(x: (f.width-3*R)/2, y: f.height - R - 24, width: 3*R, height: R)
        btn.config(with: "Next", color: Color.primary, font:  UIFont(name: FontName.bold, size: AppFontSize.footerBold+2))
        btn.backgroundColor = Color.redDark
        btn.addTarget(self, action: #selector(handleTapJoin), for: .touchUpInside)
        view.addSubview(btn)
    }
    
    
    @objc private func ptr(_ sender: Any) {
        reload()
        self.refreshControl.endRefreshing()
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let f = view.frame
        let (kind,_,_) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return 10
        case .padEnd:
            return 50
        case .banner:
            return 30 + AppFontSize.body2*2
        case .hero:
            return OnboardHeroCell.Height( width: f.width)
        case .headerA:
            return AppFontSize.body2+10
        case .tags:
            return 70.0
        }
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let ( kind, str, tags ) = dataSource[row]
        
        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        case .padEnd:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        case .banner:
            let str = self.club?.getOrg()?.get_H1() ?? ""
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerCell", for: indexPath) as! BannerCell
            cell.config(with: str, color: Color.redDark)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        case .hero:
            let str = self.club?.getOrg()?.get_H3() ?? ""
            let url = self.club?.getOrg()?.fetchThumbURL()
            let cell = tableView.dequeueReusableCell(withIdentifier: "OnboardHeroCell", for: indexPath) as! OnboardHeroCell
            cell.config(with: url, str: str, color: bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        case .headerA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH3Cell", for: indexPath) as! HeaderH3Cell
            cell.config(with: str, textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        case .tags:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath) as! TagCell
            cell.config(with: tags, actives: self.selected)
            cell.delegate = self
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        }
    }
    
    func placeIndicator(){
        
        if self.awaitView != nil { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: "Syncing")
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



private func to2DArray( _ reduced: [TagModel] ) -> [[TagModel]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/2) + 1
    
    while num > 0 {
        patternArray.append([0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    return res
}
