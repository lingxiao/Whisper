//
//  ProfileController+Table.swift
//  byte
//
//  Created by Xiao Ling on 7/30/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit




private let BioFontSize = AppFontSize.footer


extension ProfileController: UITableViewDataSource, UITableViewDelegate  {
    
    func layoutHeader( _  isHome : Bool ){
        let f = view.frame
        let rect = CGRect(x:0,y:0,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.delegate = self
        header.config( showSideButtons: true, left: "", right: isHome ? "" : "xmark", title: "Profile", mode: .light )
        view.addSubview(header)
        header.backgroundColor = Color.primary
        self.header = header
    }
    
    func layoutTable( isHome: Bool ){
        
        let f = view.frame
        let table = UITableView(frame: CGRect(x:0,y:statusHeight,width:f.width,height:f.height-statusHeight))

        // register cells
        table.register(PadCell.self     , forCellReuseIdentifier: PadCell.identifier )
        table.register(HeroCell.self    , forCellReuseIdentifier: HeroCell.identifier)
        table.register(TextCell.self    , forCellReuseIdentifier: TextCell.identifier)
        table.register(SocialCell.self  , forCellReuseIdentifier: SocialCell.identifier)
        table.register(HeaderH1Cell.self, forCellReuseIdentifier: HeaderH1Cell.identifier)
        table.register(UserRowCell.self , forCellReuseIdentifier: UserRowCell.identifier)

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
        refreshControl.alpha = 0

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
            return indexPath.row == 0 ? 25 : 10
        case .none:
            return 1.0
        case .hero:
            return 120 + AppFontSize.H2 + 30
        case .bio:
            let f = view.frame
            let bio = self.user?.get_H2() ?? ""
            let ht = TextCell.Height(for: bio, width: f.width-30, font: UIFont(name:FontName.regular,size:BioFontSize))
            return bio == "" ? 2.0 : ht
        case .follow:
            return 70
        case .title:
            return AppFontSize.body+20
        case .follower:
            return 70
        }

    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let (kind, muser) = dataSource[indexPath.row]

        switch kind {

        case .pad:

            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell

        case .none:

            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell

        case .hero:

            let cell = tableView.dequeueReusableCell(withIdentifier: "HeroCell", for: indexPath) as! HeroCell
            cell.config(with: self.user, nameFont: UIFont(name: FontName.bold, size: AppFontSize.H1))
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .bio:
            
            let bio = self.user?.get_H2() ?? ""
            let (num,_) = computeLabelHt()
            let align : NSTextAlignment = num > 2 ? .left : .center
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as! TextCell
            cell.config(with: bio, font: UIFont(name: FontName.regular, size: BioFontSize)!, textAlignment: align)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell

        case .follow:

            let cell = tableView.dequeueReusableCell(withIdentifier: "SocialCell", for: indexPath) as! SocialCell
            cell.config(with: self.user, nameFont: UIFont(name: FontName.bold, size: AppFontSize.H1))
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            cell.delegate = self
            return cell
            
        case .title:
            
            let str = "People I share a channel with"
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: str, textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .follower:

            let cell = tableView.dequeueReusableCell(withIdentifier: "UserRowCell", for: indexPath) as! UserRowCell
            cell.config(with: muser, button: true)
            cell.backgroundColor = Color.primary
            cell.delegate = self
            return cell

        }
    }
    
    private func computeLabelHt() -> (Int,CGFloat) {
        
        guard let user = user else { return (1,BioFontSize) }
        
        if user.get_H2() == "" {
            return (1,2.0)
        } else {
            let v  = UILabel(frame: CGRect(x:20,y:0, width:view.frame.width-40, height:0))
            v.body2()
            v.text = user.get_H2()
            v.textAlignment = .left
            let maxNum = v.maxNumberOfLines
            return ( maxNum, maxNum == 1
                        ? 2*v.requiredHeight
                        : maxNum <= 5
                            ? v.requiredHeight + BioFontSize
                            : v.requiredHeight - 1.5*BioFontSize
            )
        }
    }

}


