//
//  DeckAudienceController.swift
//  byte
//
//  Created by Xiao Ling on 1/16/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- types

enum DeckAudienceControllerCellKind {
    case pad
    case headerA
    case headerB
    case item
}

typealias DeckAudienceControllerData = [(DeckAudienceControllerCellKind,DeckAudience?)]

protocol DeckAudienceControllerDelegate {
    func onDismiss( this deck: DeckAudienceController ) -> Void
}


//MARK:- class

class DeckAudienceController: UIViewController {

    var isModal : Bool = true
    var delegate: DeckAudienceControllerDelegate?

        
    // data
    var club: Club?
    var deck: FlashCardDeck?
    var dataSource : DeckAudienceControllerData = []
    
    // style
    let headerHeight: CGFloat = 60
    var statusHeight : CGFloat = 10.0

    var header: AppHeader?
    var tableView: UITableView?
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {

        super.viewDidLoad()
        primaryGradient(on: self.view)

        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
        addGestureResponders()
    }
    
    //MARK:- API
    
    func config( with deck: FlashCardDeck?, on club: Club?, isModal: Bool, hasHeader: Bool = true ){

        self.deck = deck
        self.club = club
        self.isModal = isModal

        layout( hasHeader )
        refresh()
        
        if !isModal {
            if let header = self.header {
                tableView?.tableHeaderView = header
            }
        }
    }
    
    func refresh(){

        guard let deck = deck else { return }

        let users = Array(deck.checkin_history.values)
        let here = users.filter{ deckAudienceIsHere(for:$0) }
        let not_here = users.filter{ !deckAudienceIsHere(for:$0) }
        
        var res : DeckAudienceControllerData = [(.pad,nil)]

        if here.count > 0 {
            let xs = here.sorted{ $0.checkin > $1.checkin }
            res.append((.headerA,nil))
            res.append(contentsOf: xs.map{ (.item,$0) })
        }
        
        if not_here.count > 0 {
            let xs = not_here.sorted{ $0.checkin > $1.checkin }
            res.append((.headerB,nil))
            res.append(contentsOf: xs.map{ (.item,$0) })
        }
        
        self.dataSource = res
        self.tableView?.reloadData()
    }
    
}

//MARK:- responder

extension DeckAudienceController: ClubDiscoveryCellProtocol, AppHeaderDelegate {
    
    func onHandleDismiss() {
        if self.isModal {
            delegate?.onDismiss(this: self)
        } else {
            AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
        }
    }

    func handleTap(on user: DeckAudience?) {
        
        heavyImpact()
        guard let user = user?.user else { return }
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func handleBtn(on user: DeckAudience?) {

        heavyImpact()
        
        guard let user = user?.user else { return }
        guard let club = self.club else { return }

        let bod = "Invite \(user.get_H1()) into your cohort"
        let optionMenu = UIAlertController(title: "Invite", message: bod, preferredStyle: .actionSheet)
            
        let deleteAction = UIAlertAction(title: "Invite", style: .default, handler: { a in
            if user.isMe() {
                ToastSuccess(title: "That's you!", body: "")
            } else {
                setAlert(for: user.uuid, kind: .inviteToGroup, meta: club.uuid)
                ToastSuccess(title: "Invite sent!", body: "")
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel )
            
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        AuthDelegate.shared.home?.present(optionMenu, animated: true, completion: nil)
    }
    
}

//MARK:- table

extension DeckAudienceController: UITableViewDataSource, UITableViewDelegate { 
                                  //ClubDirectoryCellDelegate {
    
    func onTapNewClub( at club: Club? ){
        heavyImpact()
    }

    func onFollowClub( at club: Club? ){
        return
    }
    
    // layout table
    private func layout( _ hasHeader: Bool ){

        let f = self.view.frame
        var dy : CGFloat = self.isModal ? 0 : statusHeight
        
        if hasHeader {
            let header = AppHeader(frame: CGRect(x: 0, y: 0, width: f.width, height: headerHeight))
            header.config(showSideButtons: true, left: "", right: "xmark", title: "Seen by", mode: .dark, small: true)
            header.delegate = self
            view.addSubview(header)
            header.backgroundColor = UIColor.clear
            self.header = header
        }
        
        if self.isModal {
            dy += headerHeight
        }
        
        let table: UITableView = UITableView(frame: CGRect(x:0,y:dy,width:f.width,height:f.height-dy))
        
        // register cells
        table.register(LineCell.self, forCellReuseIdentifier: LineCell.identifier )
        table.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        table.register(HeaderH1Cell.self, forCellReuseIdentifier: HeaderH1Cell.identifier)
        table.register(ClubDiscoveryCell.self, forCellReuseIdentifier: ClubDiscoveryCell.identifier)

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
        heavyImpact()
        refresh()
        self.refreshControl.endRefreshing()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        if let _ = self.tableView?.tableHeaderView as? AppHeader {
            return
        }
    }

    
    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let ( kind, item ) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return 5.0
        case .headerA:
            return AppFontSize.body+20
        case .headerB:
            return AppFontSize.body+20
        case .item:
            if let _ = item {
                return 70.0
            } else {
                return 1.0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let ( kind, aud ) = dataSource[indexPath.row]

        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: UIColor.clear)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell
            
        case .headerA:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Here right now", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell

        case .headerB:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "History", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell

        case .item:

            if let user = aud {
                    
                let cell = tableView.dequeueReusableCell(withIdentifier: "ClubDiscoveryCell", for: indexPath) as! ClubDiscoveryCell
                cell.config(with: user, button: true)
                cell.delegate = self
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor.clear
                return cell
                
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
                cell.config(color: UIColor.clear)
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor.clear
                return cell
            }
            
        }
    }
    

}

extension DeckAudienceController {
    
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
                if !self.isModal {
                    onHandleDismiss()
                }
            default:
                break
            }
        }
    }

}
