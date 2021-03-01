//
//  UserList+Table.swift
//  byte
//
//  Created by Xiao Ling on 7/30/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit




//MARK:- render cells

extension UserListController: UITableViewDataSource, UITableViewDelegate  {
    
    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0 ){
            return 25
        } else {
            return 70
        }
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count + self._data_source_off_set
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        if ( row == 0 ){

            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.contentView.backgroundColor = Color.primary
            cell.selectionStyle = .none
            return cell
            
        } else {

            let data = dataSource[row - self._data_source_off_set]
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserRowCell", for: indexPath) as! UserRowCell
            cell.config(with: data, button: true)
            cell.delegate = self
            cell.backgroundColor = Color.primary
            return cell
            
        }
    }
    
    func layoutHeader(){
        let f = view.frame
        let h = AppHeader(frame: CGRect( x: 0, y: pad_top, width: f.width, height: headerHeight ))
        h.config( showSideButtons: true, left: "", right: "xmark", title: self.name, mode: .light )
        h.delegate = self
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
    }
    
    func setUpTableView(){

        let table: UITableView = UITableView(frame: CGRect(
              x: 0
            , y: pad_top + headerHeight
            , width: self.view.frame.width
            , height: self.view.frame.height - pad_top - headerHeight
        ))
        
        // register cells
        table.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        table.register(UserRowCell.self, forCellReuseIdentifier: UserRowCell.identifier)

        // mount
        self.tableView = table
        self.view.addSubview(table)
        
        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.backgroundColor = Color.primary
        self.tableView?.separatorStyle = .none


    }
    
}

