//
//  OrgListController.swift
//  byte
//
//  Created by Xiao Ling on 2/27/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- datatypes-

enum OrgListCellKind {
    case pad
    case headerA
    case item
}

typealias OrgListData = [(OrgListCellKind,OrgModel?)]
private let BioFontSize = AppFontSize.footer

private let bkColor = Color.primary
private let cellColor = Color.white


protocol OrgCellDelegate {
    func ontap( org: OrgModel? ) -> Void
}

//MARK:- class-

/*
 @Use: renders my groups
*/
class OrgListController: UIViewController, OrgCellDelegate {
    
    var delegate: OrgCellDelegate?

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
    var dataSource : OrgListData = []

    // pull to refresh
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
    }
    
    func config( width: CGFloat ) {
        self.view.backgroundColor = bkColor
        layout( for: width )
        refresh()
        let _ = self.view.addBorder(width: 1.0, color: UIColor.white.cgColor)

    }

    func refresh(){
        var res : OrgListData = [(.pad,nil),(.headerA,nil),(.pad,nil)]
        let tail: OrgListData = ClubList.shared.fetchNewsFeed().map{ (.item,$0.0) }
        res.append(contentsOf:tail)
        res.append((.pad,nil))
        self.dataSource = res
        tableView?.reloadData()  
    }
    
    func ontap( org: OrgModel? ){
        UserAuthed.shared.setCurrentOrg(to: org?.uuid)
        delegate?.ontap(org: org)
    }
    
}

//MARK:- table-


extension OrgListController: UITableViewDataSource, UITableViewDelegate  {
    
    func layout( for width: CGFloat ){
        
        let f   = view.frame
        let dy = statusHeight
        
        let table: UITableView = UITableView(frame: CGRect(x:0,y:dy,width:width,height:f.height-dy))
        table.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        table.register(OrgCell.self , forCellReuseIdentifier: OrgCell.identifier)
        table.register(HeaderH1Cell.self, forCellReuseIdentifier: HeaderH1Cell.identifier )

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

        let (kind,_) = dataSource[indexPath.row]

        switch kind {
        case .pad:
            return 15
        case .headerA:
            return AppFontSize.H2+20
        case .item:
            return OrgCell.Height()
        }

    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let (kind, org) = dataSource[indexPath.row]

        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: UIColor.clear)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell

        case .headerA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Subscribed", textColor: Color.primary_dark, font: UIFont(name: FontName.icon, size: AppFontSize.H2)!)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell

        case .item:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrgCell", for: indexPath) as! OrgCell
            cell.config(with: org)
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }
    }
    

}



//MARK:- one room view-


private class OrgCell: UITableViewCell {
    
    static let identifier = "OrgCell"

    var org : OrgModel?
    var delegate: OrgCellDelegate?
    var child: UIImageView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        child?.removeFromSuperview()
    }
    
    func config( with org: OrgModel? ){
        self.org = org
        let _ = self.tappable(with: #selector(onTap))
        layout()
    }
    
    @objc func onTap(){
        delegate?.ontap(org: self.org)
    }

    static func Height() -> CGFloat {
        var dy : CGFloat = 10
        let R : CGFloat = 60
        let ht = AppFontSize.footerBold
        dy += 20
        dy += ht + 5
        dy += R + 15
        return dy
    }
    
    private func layout(){

        let f = self.frame

        let dx : CGFloat = 10
        let width = f.width - 2*dx
        var dy: CGFloat = 10
        let R : CGFloat = 60
        let ht: CGFloat = AppFontSize.footerBold
        let wd = width - R - 10
        self.backgroundColor = bkColor
       
        let v = UIImageView(frame: CGRect(x: dx, y: 0, width: width, height: f.height-20))
        v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        v.backgroundColor = cellColor
        addSubview(v)
        self.child = v
        
        v.addBottomBorderWithColor(color:Color.graySecondary,width:4.0)
        v.addRightBorderWithColor(color:Color.graySecondary,width:3.0)
                
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: dy, width: wd, height: ht)
        h1.verticalAlignment = .middle
        h1.textAlignment = .left
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        h1.textColor = Color.grayPrimary
        h1.backgroundColor = cellColor
        v.addSubview(h1)
        
        if GLOBAL_DEMO {
            let n = Int.random(in: 13..<43)
            h1.text = "\(n) people are live here"
        } else {
            let n = org?.getActiveUsers().count ?? 0
            if n > 0 {
                h1.text = n == 1 ? "1 person is live" : "\(n) people are live"
                h1.textColor = Color.redDark
            } else {
                let clubs = ClubList.shared
                    .fetchClubsFor(school: org)
                    .sorted{ $0.timeStampLatest > $1.timeStampLatest }
                if clubs.count > 0 {
                    h1.text = "Active \(computeAgo(from: clubs[0].timeStampLatest))"
                }
            }
        }
        
        // make image
        dy += ht + 5
        
        let p = UIImageView(frame: CGRect(x: dx, y: dy, width: R, height: R))
        let _ = p.corner(with:R/8)
        p.backgroundColor = Color.blue1

        // creator
        let h2 = UITextView()
        h2.isUserInteractionEnabled = false
        h2.frame = CGRect( x:dx+R+5, y: dy, width: wd-10, height: R/2)
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byTruncatingTail
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = cellColor
        h2.text = org?.get_H1() ?? ""
        
        v.addSubview(h2)
        v.addSubview(p)
                
        dy += R/2
        
        // row of profile pictures
        var head: [URL?] = []
        var tail: [URL?] = []
        
        if GLOBAL_DEMO {
            for (_,user) in UserList.shared.cached {
                if let url = user.fetchThumbURL() {
                    head.append(url)
                } else {
                    tail.append(user.fetchThumbURL())
                }
            }
        } else {
            if let users = self.org?.getRelevantUsers() {
                let urls = users.map{ $0.fetchThumbURL() }
                head = urls.filter{ $0 != nil }
                tail = urls.filter{ $0 == nil }
            }
        }
                
        head.append(contentsOf: tail)
        let vp = PictureRow()
        vp.frame = CGRect(x: dx + R + 10, y: dy, width:wd-10, height:R/3)
        vp.config(with: head, gap: ht*1.2/3, numPics: 3)
        v.addSubview(vp)
        
        // inject data
        DispatchQueue.main.async {
            if let url = self.org?.fetchThumbURL() {
                ImageLoader.shared.injectImage(from: url, to: p){ _ in return }
            } else {
                var char : String = ""
                char = String(  self.org?.get_H1().prefix(1) ?? "" )
                let sz = R/3
                let ho = UILabel(frame: CGRect(x: (R-sz)/2, y: (R-sz)/2, width: sz, height: sz))
                ho.font = UIFont(name: FontName.bold, size: sz)
                ho.textAlignment = .center
                ho.textColor = Color.grayQuaternary.darker(by: 50)
                ho.text = char.uppercased()
                p.addSubview(ho)
            }
        }
    }
    
    

}
