//
//  BreakoutDirectory.swift
//  byte
//
//  Created by Xiao Ling on 1/26/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView
import SwiftEntryKit

//MARK:- protocol + type


enum BreakoutDirectoryCell {
    case pad
    case roomRow
    case term_pad
}

typealias BreakoutDirectoryData = [(BreakoutDirectoryCell, [Room])]


//MARK:- class


/*
 @Use: renders my groups
*/
class BreakoutDirectory: UIViewController {
        
    // delegate + parent
    var delegate: ExploreParentProtocol?
    
    // style
    let headerHeight: CGFloat = 50
    let footerHeight: CGFloat = 80
    var statusHeight : CGFloat = 10.0
    var buttonHeight: CGFloat = AppFontSize.footer + 30

    // main child view
    var header: AppHeader?
    var emptyLabel: UITextView?
    var tableView: UITableView?
    var awaitView: AwaitWidget?
    let refreshControl = UIRefreshControl()

    // databasource
    var club: Club?
    var dataSource : BreakoutDirectoryData = []
    
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
    func config( with club: Club? ){
        self.club = club
        layout()
        refresh()
        if let header = self.header {
            tableView?.tableHeaderView = header
        }
        listenRoomDidDelete(on: self, for: #selector(didDeleteRoom))
        listenBreakoutRoomDidAdd(on:self,for: #selector(didAddRoom))
    }
    
    @objc func didDeleteRoom(_ notification: NSNotification){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.refresh()
        }
    }
    
    @objc func didAddRoom(_ notification: NSNotification){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            self?.refresh()
        }
    }

    func refresh(){
        
        guard let club = self.club else { return }
        
        var res : BreakoutDirectoryData = [ (.pad,[]) ]

        var breakouts: [Room] = []
        
        if GLOBAL_DEMO {
            if let room = club.getRootRoom() {
                breakouts.append(contentsOf: [room,room,room,room,room,room])
            }
        } else {
            breakouts = club.getBreakoutRooms()
        }
        
        let rooms: BreakoutDirectoryData = to2DArray(breakouts).map{ (.roomRow, $0) }
        res.append(contentsOf: rooms)
        res.append( (.term_pad,[]) )
        self.dataSource = res
        tableView?.reloadData()
        
        if breakouts.count == 0 {
            layoutEmpty()
        } else {
            self.emptyLabel?.removeFromSuperview()
        }
    }
    
    @objc private func ptr(_ sender: Any) {
        refresh()
        self.refreshControl.endRefreshing()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        /*if let headerView = self.tableView?.tableHeaderView as? AppHeader {
            headerView.scrollViewDidScroll(scrollView: scrollView)
        }*/
    }
    
    func didTap(on deck: FlashCardDeck? ){
        delegate?.onHandleTapDeck(on: deck)
    }
    
    @objc func handleTapAdd( _ button: TinderButton ){
        let f = view.frame
        let ratio = ConfirmBreakoutRoomModal.height()/f.height
        let attributes = centerToastFactory(ratio: ratio, displayDuration: 100000)
        let modal = ConfirmBreakoutRoomModal()
        modal.delegate = self
        modal.config( width: f.width-20, h1: "Exit main room and create breakout room", h2: "", h3: "Exit and create")
        SwiftEntryKit.display(entry: modal, using: attributes)
    }
    
}


//MARK: -events-

extension BreakoutDirectory: ConfirmBreakoutRoomModalDelegate, BreakoutRoomCellDelegate {
    
    // navigate to room
    func onTapRoom( at room: Room? ){
        let vc = AudioRoomController()
        vc.view.frame = UIScreen.main.bounds
        vc.config(with: room, club: club)
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }

    // create new room
    func onPressConfirm(){

        SwiftEntryKit.dismiss()
        if self.awaitView != nil { return }
        guard let club = club else { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: "One moment")
        view.addSubview(pv)
        self.awaitView = pv
            
        club.createBreakoutRoom(){ id in

            if let room = club.rooms[id] {
                self.refresh()
                self.onTapRoom(at: room)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) { [weak self] in
                    self?.hideIndicator()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                    self?.hideIndicator()
                    self?.refresh()
                }
            }
        }

        //max duration is six seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 ) { [weak self] in
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



//MARK:- table


extension BreakoutDirectory: UITableViewDataSource, UITableViewDelegate {
    
    private func layoutEmpty(){
        
        self.emptyLabel?.removeFromSuperview()
        
        let f = view.frame
        let ht = AppFontSize.H3*2
        let h2 = UITextView(frame:CGRect(x:20,y:(f.height-ht)/2,width:f.width-40, height:ht))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.body2)
        h2.text = "There are no breakout rooms"
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = UIColor.clear
        h2.isUserInteractionEnabled = false
        self.view.addSubview(h2)
        self.emptyLabel = h2
        self.view.bringSubviewToFront(h2)
    }
    
    private func layout(){
        
        let f = view.frame
        var dy = statusHeight
        let rect = CGRect(x:0,y:0,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.config( showSideButtons: false, title: "Breakout Rooms", small: true )
        view.addSubview(header)
        header.backgroundColor = UIColor.clear
        self.header = header

        dy += headerHeight

        let ht = f.height - statusHeight
        let table = UITableView(frame:CGRect(x:0,y:statusHeight,width:f.width,height:ht))
        self.view.addSubview(table)
        self.tableView = table
            
        // register cells
        tableView?.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        tableView?.register(BreakoutRoomCell.self, forCellReuseIdentifier: BreakoutRoomCell.identifier )
        

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.separatorStyle = .none
        tableView?.backgroundColor = UIColor.clear
        
        // PTR
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(ptr(_:)), for: .valueChanged)
        refreshControl.alpha = 0.0
        
        // button
        let wd = f.width/3
        let b2 = TinderTextButton()
        b2.frame = CGRect(x:(f.width-wd)/2,y: f.height-buttonHeight-20, width:wd,height:buttonHeight)
        b2.config(with: "New room", color: Color.primary, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        b2.addTarget(self, action: #selector(handleTapAdd), for: .touchUpInside)
        b2.backgroundColor = Color.redDark
        view.addSubview(b2)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let (kind,_) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return 10
        case .term_pad:
            return computeTabBarHeight() + buttonHeight
        case .roomRow:
            let f = view.frame
            let wd = (f.width - 2*15 - 10)/2
            return wd + CardDirectoryCell.textHeight
        }
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let ( kind, rooms ) = dataSource[row]
        
        switch kind {
        
        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.white)
            cell.selectionStyle = .none
            return cell
            
        case .term_pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.white)
            cell.selectionStyle = .none
            return cell
            
        case .roomRow:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BreakoutRoomCell", for: indexPath) as! BreakoutRoomCell
            cell.config( with: rooms, row: row )
            cell.selectionStyle = .none
            cell.delegate = self
            cell.backgroundColor = Color.white
            return cell
        }
    }

}


private func to2DArray( _ reduced: [Room] ) -> [[Room]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/2) + 1
    
    while num > 0 {
        patternArray.append([0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    let sm = res.filter{ $0.count > 0 }
    return sm
}

