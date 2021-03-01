//
//  InviteUser+Table.swift
//  byte
//
//  Created by Xiao Ling on 11/1/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



extension InviteUserController: UITableViewDataSource, UITableViewDelegate {
    
    // set up table
    func setUpTableView( _ showHeader : Bool ){

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
        table.register(UserRowCell.self    , forCellReuseIdentifier: UserRowCell.identifier)

        // mount
        self.tableView = table
        self.view.addSubview(table)

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserRowCell", for: indexPath) as! UserRowCell
        cell.config(with: data, button: false)
        cell.backgroundColor = UIColor.clear //Color.primary
        cell.delegate = self
        cell.highlight(selected.contains(data))
        return cell

    }


       
}
