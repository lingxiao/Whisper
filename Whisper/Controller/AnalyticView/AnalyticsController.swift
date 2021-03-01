//
//  AnalyticsController.swift
//  byte
//
//  Created by Xiao Ling on 2/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

protocol AnalyticsControllerDelegate {
    func onHandleHideAnalyticsController( at vc: AnalyticsController )
}


private let bkColor = Color.primary

enum AnalyticsControllerCellKind {
    case pad
    case bot_pad
    case item
    case lineBreak
}

typealias AnalyticsDataSource =  [(AnalyticsControllerCellKind,SpeakerLog?)]

class AnalyticsController : UIViewController {
    
    var delegate: AnalyticsControllerDelegate?
    
    // data
    var club: Club?
    var room: Room?
    var dataSource: AnalyticsDataSource = []
        
    // style
    var headerHeight: CGFloat = 70
    var statusHeight : CGFloat = 10.0
    var showHeader: Bool = true

    // view
    var header: AppHeader?
    var emptyLabel: UITextView?
    var tableView: UITableView?
    var refreshControl = UIRefreshControl()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureResponders()
    }

    public func config( with club: Club?, at room: Room? ){

        self.club = club
        self.room = room
        view.backgroundColor = bkColor
        layout()
        reload()
    }
    
    func reload(){

        var res : AnalyticsDataSource = [(.pad,nil)]

        let bod : AnalyticsDataSource = WhisperAnalytics
            .shared
            .getLog(for: club, at: room)
            .sorted{ $0.start > $1.start }
            .map{ (.item, $0) }

        for item in bod {
            res.append(item)
            res.append((.lineBreak,nil))
        }
        res.append((.bot_pad, nil))
        self.dataSource = res
        tableView?.reloadData()
        
        if bod.count == 0 {
            layoutEmpty()
        } else {
            emptyLabel?.removeFromSuperview()
        }
    }

}


//MARK:- view

extension AnalyticsController {

    func layout(){

        let f = view.frame
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Speaker log", mode: .light )
        view.addSubview(header)
        header.backgroundColor = bkColor
        header.delegate = self
        self.header = header
        
        let dy = headerHeight+statusHeight
        let table: UITableView = UITableView(frame: CGRect(x:0,y:dy,width:f.width,height:f.height-dy))
        table.register(LineCell.self, forCellReuseIdentifier: LineCell.identifier )
        table.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        table.register(AnalyticCell.self, forCellReuseIdentifier: AnalyticCell.identifier)
        table.register(AnalyticSeparationCell.self, forCellReuseIdentifier: AnalyticSeparationCell.identifier)

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
    
    func layoutEmpty(){
        self.emptyLabel?.removeFromSuperview()
        let f = view.frame
        let ht = AppFontSize.H3*2
        let h2 = UITextView(frame:CGRect(x:20,y:(f.height-ht)/2,width:f.width-40, height:ht))
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h2.text = "No one has spoken yet"
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = bkColor
        h2.isUserInteractionEnabled = false
        self.view.addSubview(h2)
        self.emptyLabel = h2
        self.view.bringSubviewToFront(h2)
    }
    
    @objc private func ptr(_ sender: Any) {
        heavyImpact()
        reload()
        self.refreshControl.endRefreshing()
    }
    

}


//MARK:- table

extension AnalyticsController: UITableViewDataSource, UITableViewDelegate {


    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let ( kind, _ ) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return 5.0
        case .bot_pad:
            return 40.0
        case .item:
            return 70.0
        case .lineBreak:
            return 15
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let ( kind, log ) = dataSource[indexPath.row]

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

        case .item:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnalyticCell", for: indexPath) as! AnalyticCell
            cell.config(with: log)
//            cell.delegate = self
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
            
        case .lineBreak:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnalyticSeparationCell", for: indexPath) as! AnalyticSeparationCell
            cell.config(color: Color.grayQuaternary)
            cell.selectionStyle = .none
            cell.backgroundColor = bkColor
            return cell
        }
    }
    

}

//MARK:- gesture

extension AnalyticsController : AppHeaderDelegate {

    func onHandleDismiss() {
        self.delegate?.onHandleHideAnalyticsController(at: self)
    }
    
    func addGestureResponders(){
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .right
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            default:
                self.delegate?.onHandleHideAnalyticsController( at: self )
                break
            }
        }
    }

    
}

