//
//  InviteGroupModal.swift
//  byte
//
//  Created by Xiao Ling on 12/23/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//



import Foundation
import UIKit
import SwiftEntryKit


protocol InviteGroupModalDelegate {
    func onHandleAlertMe( with club: Club, at room: Room?, for user: User ) -> Void
    func onHandleRemove( with club: Club, at room: Room?, for user: User ) -> Void
    func onSitDown( for user: User? ) -> Void
    func onAddToGroup( for user: User? ) -> Void
    func onHandleGoToProfile( to user: User ) -> Void
}


class InviteGroupModal: UIView, RoomHeaderCellDelegate {
    
    // data
    var user : User?
    var delegate: RoomHeaderCellDelegate?
    var dataSource:[Club] = []
    
    // view
    var header: AudioRoomHeader?
    var tableView: UITableView?
    
    //style
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        let num = InviteGroupModal.getMyclubs().count
        let h1 = CGFloat(10.0 + AppFontSize.H1 + 10.0 + CGFloat(num) * 70)
        let h2 = CGFloat(UIScreen.main.bounds.height/2)
        return h1 > h2 ? h2 : h1
    }
    
    static func getMyclubs() -> [Club] {
        return Array(ClubList.shared.clubs.values).filter{ $0.iamAdmin() && $0.deleted == false }
    }

    func config( for user: User?, width: CGFloat ){
        self.user  = user
        self.width = width
        layout()
        self.dataSource = InviteGroupModal.getMyclubs()
        self.tableView?.reloadData()
    }
    
    
    func handleTapRoomHeader( on club: Club?, from room: Room?, with user: User? ){
        delegate?.handleTapRoomHeader(on: club, from: room, with: self.user )
    }

    //MARK:- view
    
    private func layout(){
        
        let parent = UIView(frame: CGRect(x: 10, y: 0, width: self.width, height: InviteGroupModal.height()))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        var dy: CGFloat = 10

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)

        // add header
        let h1 = UITextView(frame:CGRect(x:15,y:dy,width:width-15, height:AppFontSize.H1))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = "Invite to my groups"
        h1.textColor = Color.primary_dark
        h1.textAlignment = .left
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        
        dy += AppFontSize.H1 + 10
        
        let table = layoutTable(dy: dy, height: InviteGroupModal.height() - dy - 10 )
        parent.addSubview(table)

    }
}


//MARK:- table

extension InviteGroupModal: UITableViewDataSource, UITableViewDelegate {
    
    func layoutTable( dy: CGFloat, height ht: CGFloat ) -> UITableView {
        
        let table = UITableView(frame:CGRect(x:0,y:dy,width:self.width,height:ht))
        self.tableView = table
            
        // register cells
        tableView?.register(RoomHeaderCell.self, forCellReuseIdentifier: RoomHeaderCell.identifier )

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.separatorStyle = .none
        tableView?.backgroundColor =  Color.primary
        
        return table
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row

        let cell  = tableView.dequeueReusableCell(withIdentifier: RoomHeaderCell.identifier, for: indexPath) as! RoomHeaderCell
        cell.selectionStyle = .none
        cell.config( with: dataSource[row], room: nil )
        cell.delegate = self
        return cell

    }

}

