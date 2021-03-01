//
//  Calendar+View.swift
//  byte
//
//  Created by Xiao Ling on 2/14/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import NVActivityIndicatorView

import EventKit
import EventKitUI



//MARK:- view

extension CalendarController {

    func layout(){

        let f = view.frame
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Calendar", mode: .light )
        view.addSubview(header)
        header.backgroundColor = self.bkColor
        header.delegate = self
        self.header = header

        let dy = headerHeight+statusHeight
        let table: UITableView = UITableView(frame: CGRect(x:0,y:dy,width:f.width,height:f.height-dy))
        table.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        table.register(CalendarCell.self, forCellReuseIdentifier: CalendarCell.identifier)
        table.register(HeaderH1Cell.self, forCellReuseIdentifier: HeaderH1Cell.identifier )

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
        
        // add btn
        let bht = AppFontSize.footer + 30
        let btn = TinderTextButton()
        btn.frame = CGRect(x: 0, y: f.height-30-bht, width: f.width/3, height: bht)
        btn.center.x = view.center.x
        btn.config(with: "Add event", color: Color.white, font: UIFont(name: FontName.bold, size: AppFontSize.footer))
        btn.backgroundColor = Color.redDark
        view.addSubview(btn)
        btn.addTarget(self, action: #selector(handleTapNewEvent), for: .touchUpInside)

    }
    
    func layoutEmpty(){
        self.emptyLabel?.removeFromSuperview()
        let f = view.frame
        let ht = AppFontSize.H3*2
        let h2 = UITextView(frame:CGRect(x:20,y:(f.height-ht)/2,width:f.width-40, height:ht))
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h2.text = "There are no upcoming events"
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = self.bkColor
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
    
    func placeIndicator(){
        
        if self.awaitView != nil { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: "Creating room")
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


//MARK:- table

extension CalendarController: UITableViewDataSource, UITableViewDelegate {


    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let ( kind, evt ) = dataSource[indexPath.row]

        switch kind {
        case .pad:
            return 5.0
        case .bot_pad:
            return 60.0
        case .item:
            let str = WhisperCalendar.shared.get_H1(for: evt)
            return CalendarCell.Height(for: str, width: view.frame.width-30)
        case .headerA:
            return AppFontSize.body+20
        case .headerB:
            return AppFontSize.body+20
        case .headerC:
            return AppFontSize.body+20
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let ( kind, evt ) = dataSource[indexPath.row]

        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: self.bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = self.bkColor
            return cell
            
        case .bot_pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: self.bkColor)
            cell.selectionStyle = .none
            cell.backgroundColor = self.bkColor
            return cell

        case .item:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
            cell.config(with: evt)
            cell.delegate = self
            cell.selectionStyle = .none
            cell.backgroundColor = self.bkColor
            return cell
            
        case .headerA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Live now", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = self.bkColor
            return cell

        case .headerB:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "My events", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = self.bkColor
            return cell
            
        case .headerC:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Upcoming", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = self.bkColor
            return cell

        }
    }
    

}



//MARK:- cell:-

protocol CalendarCellDelegate  {
    func onDidRSVp(from event: WhisperEvent?) -> Void
    func onTapCell(from event: WhisperEvent?) -> Void
}

class CalendarCell: UITableViewCell {
    
    static let identifier = "CalendarCell"
    
    let bkColor = Color.white

    
    var h1: UITextView?
    var h2: UITextView?
    var h3: UITextView?
    var pics: PictureRow?
    var icon: TinderButton?
    
    var event: WhisperEvent?
    var delegate: CalendarCellDelegate?
    
    var pictures: [URL?] = []
    
    static func Height( for str: String, width: CGFloat ) -> CGFloat {
        var dy: CGFloat = 10
        let ht2 = CalendarCell.notesHeight(for: str, width: width)
        dy += AppFontSize.footer + 10
        dy += AppFontSize.body2 + 10
        dy += ht2
        dy += 30
        return dy
    }
    
    static func notesHeight( for str: String, width: CGFloat ) -> CGFloat {
        let h2 = UITextView()
        h2.frame = CGRect(x: 15, y: 0, width: width, height: AppFontSize.H2)
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.regular, size: AppFontSize.footerBold)
        h2.textColor = Color.secondary.darker(by: 50)
        h2.backgroundColor = UIColor.clear
        h2.text = str
        let contentSize = h2.sizeThatFits(h2.bounds.size)
        return contentSize.height
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        h1?.removeFromSuperview()
        h2?.removeFromSuperview()
        h3?.removeFromSuperview()
        pics?.removeFromSuperview()
        icon?.removeFromSuperview()
    }
    
    @objc func handleTap(_ button: TinderButton ){
        guard let event = event else { return }
        delegate?.onDidRSVp(from: event)
        icon?.changeImage(to: "bell-ring", alpha: 1.0, scale: 3/4, color: Color.grayPrimary.darker(by: 10))
    }

    func config( with event: WhisperEvent? ){
        
        self.event = event
        let str = WhisperCalendar.shared.get_H1(for: event)
        setImages( for: event )

        let f = frame
        var dy: CGFloat = 10
        let ht1: CGFloat = AppFontSize.footer + 10
        let ht2: CGFloat = AppFontSize.body2 + 10
        let wd = f.width-30-ht1-10
        
        let h1 = UITextView()
        h1.isUserInteractionEnabled = false
        h1.frame = CGRect(x: 15, y: dy, width: wd, height: ht1)
        h1.textAlignment = .left
        h1.textContainer.lineBreakMode = .byTruncatingTail
        h1.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h1.textColor = Color.grayPrimary.darker(by: 10)
        h1.backgroundColor = self.bkColor
        h1.text = eventStartTime(for: event)
        addSubview(h1)
        self.h1 = h1
        
        let icon = TinderButton()
        icon.frame = CGRect(x: wd+15, y: dy, width: ht1, height: ht2)
        icon.center.y = h1.center.y
        icon.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(icon)
        self.icon = icon
        
        WhisperCalendar.shared.getAttendee(for: event){ users in
            if (users.filter{ $0.isMe() }.count > 0) {
                icon.changeImage(to: "bell-ring", alpha: 1.0, scale: 3/4, color: Color.grayPrimary.darker(by: 10))
            } else {
                icon.changeImage(to: "bell", alpha: 1.0, scale: 0.8, color: Color.grayPrimary.darker(by: 10))
            }
        }

        dy += ht1

        let h2 = UITextView()
        h2.isUserInteractionEnabled = false
        h2.frame = CGRect(x: 15, y: dy, width: f.width-30, height: ht1)
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byTruncatingTail
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = self.bkColor
        h2.text = event?.name ?? ""
        addSubview(h2)
        self.h2 = h2

        dy += ht1
        
        let h3 = UITextView()
        h3.isUserInteractionEnabled = false
        h3.frame = CGRect(x: 15, y: dy, width: f.width-30, height: ht1)
        h3.textAlignment = .left
        h3.textContainer.lineBreakMode = .byWordWrapping
        h3.font = UIFont(name: FontName.regular, size: AppFontSize.footerBold)
        h3.textColor = Color.secondary.darker(by: 50)
        h3.backgroundColor = self.bkColor
        h3.text = str
        h3.sizeToFit()
        self.addSubview(h3)
        self.h3 = h3
        
        let ht3 = CalendarCell.notesHeight(for: str, width: f.width - 20)
        
        dy += ht3
        
        let wd2 = f.width/3
        let vp = PictureRow()
        vp.frame = CGRect(x:20, y: dy, width:wd2, height:20)
        vp.config(with: self.pictures, gap: 5, numPics: 3)
        addSubview(vp)
        self.pics = vp
        
        let _ = self.tappable(with: #selector(handleTapCell))

    }
    
    @objc func handleTapCell(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.onTapCell(from: self.event)
    }
    
    private func setImages( for event: WhisperEvent? ){
        
        if GLOBAL_DEMO {
            
            self.pictures = Array(UserList.shared.cached.values).map{ $0.fetchThumbURL() }

        } else {
            
            guard let event = event else { return }
            
            WhisperCalendar.shared.getAttendee(for: event){ users in
                var res : [URL?] = []
                for user in users {
                    if let url = user.fetchThumbURL() {
                        res.insert(url, at: 0)
                    } else {
                        res.append(nil)
                    }
                }
                self.pictures = res
            }
        }

    }
    
}
