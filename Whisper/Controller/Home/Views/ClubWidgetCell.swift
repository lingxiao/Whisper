//
//  ClubWidgetCell.swift
//  byte
//
//  Created by Xiao Ling on 2/14/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit
import NVActivityIndicatorView


enum ClubWidgetCellKind {
    case newRoom
    case calendar
    case shareNumber
}

protocol ClubWidgetCellDelegate {
    func onTap( at kind: ClubWidgetCellKind ) -> Void
}


private let bkColor = UIColor.white


//MARK:- Cell


/*
 @Use: display user's screen
*/
class ClubWidgetCell: UITableViewCell, ClubWidgetCellDelegate {

    static var identifier: String = "ClubWidgetCell"
    
    var parent: UIView?
    var widget: ClubWidgets?
    var delegate: ClubWidgetCellDelegate?

    fileprivate var cells : [ClubWidgetCellView] = []
    
    /*
     @use: reset all child views
     https://stackoverflow.com/questions/54188027/how-to-reset-uicollectionview-in-swift
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        for c in cells {
            c.removeFromSuperview()
        }
        self.cells = []
        parent?.removeFromSuperview()
    }
    
    func onTap(at kind: ClubWidgetCellKind){
        delegate?.onTap(at: kind)
    }

    static func Height() -> CGFloat {
        return ClubWidgetCellView.Height()
    }
    
    func config( with kinds: [ClubWidgetCellKind], for org: OrgModel? ){

        let f = self.frame
        let pv = UIView(frame: CGRect(x: 20, y: 5, width: f.width-20, height: f.height))
        pv.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 20)
        addSubview(pv)
        self.parent = pv

        //left
        var dx : CGFloat = 15
        let wd = (f.width - 2*dx - 10)/2
        let ht = f.height - 10
        
        for kind in kinds {
            let v = ClubWidgetCellView(frame: CGRect(x: dx, y: 10, width: wd, height: ht))
            v.config(with: kind, for: org)
            addSubview(v)
            v.delegate = self
            self.cells.append(v)
            dx += wd + 10
        }
        
    }
        

}


//MARK:- one room view

private class ClubWidgetCellView : UIView {
    
    var kind : ClubWidgetCellKind = .newRoom
    var org: OrgModel?
        
    var delegate: ClubWidgetCellDelegate?
    var child: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func config( with kind: ClubWidgetCellKind, for org: OrgModel? ){
        self.kind = kind
        self.org = org
        let _ = self.tappable(with: #selector(onTap))
        switch kind {
        case .newRoom:
            layoutNewRoom("Tap here to create new channel")
        case .shareNumber:
            layoutNewRoom("Tap here to invite new members")
        case .calendar:
            layoutCalender()
        }
    }
    
    @objc func onTap(){
        delegate?.onTap(at: self.kind)
    }
    
    static func Height() -> CGFloat {
        var dy : CGFloat = 10
        let R : CGFloat = 50
        let ht = AppFontSize.footerBold
        dy += 20
        dy += ht + 5
        dy += R + 15
        dy += ht*1.5
        dy += 20
        return dy
    }
    
    private func layoutNewRoom( _ str: String ){

        let f = self.frame

        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height-20))
        v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        primaryGradient(on: v)
        addSubview(v)
        self.child = v

        let h2 = UITextView()
        h2.isUserInteractionEnabled = false
        h2.frame = CGRect(x: 20, y: 30, width: f.width-40, height: f.height-60)
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h2.textColor = Color.secondary.darker(by: 50)
        h2.backgroundColor = UIColor.clear
        h2.text = str
        h2.sizeToFit()
        v.addSubview(h2)
    }
    

    private func layoutCalender(){
        
        let f = self.frame
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height-20))
        v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        v.backgroundColor = bkColor
        addSubview(v)
        self.child = v
        
        v.addBottomBorderWithColor(color:Color.graySecondary,width:4.0)
        v.addRightBorderWithColor(color:Color.graySecondary,width:3.0)
        
        let dx: CGFloat = 20
        var dy: CGFloat = 10
        let R : CGFloat = 50
        let ht: CGFloat = AppFontSize.footerBold
        let wd = f.width-dx-40-ht
        
        let (_dayOfWeek,_date) = dayOfWeekAndDay()
        
        // day of week
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: dy, width: wd, height: ht)
        h1.verticalAlignment = .middle
        h1.textAlignment = .left
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        h1.textColor = Color.redDark
        h1.backgroundColor = bkColor
        h1.text = _dayOfWeek
        v.addSubview(h1)
        
        dy += ht + 5

        // day of month
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: dy, width: v.frame.width - 2*dx, height: R)
        h2.verticalAlignment = .middle
        h2.textAlignment = .left
        h2.font = UIFont(name: FontName.bold, size: R - 10)
        h2.textColor = Color.black
        h2.backgroundColor = bkColor
        h2.text = _date
        v.addSubview(h2)
        
        dy += R
            
        // event view
        let h3 = UITextView()
        h3.isUserInteractionEnabled = false
        h3.frame = CGRect(x: dx, y: dy, width: f.width-2*dx, height: v.frame.height-dy-5)
        h3.textAlignment = .left
        h3.textContainer.lineBreakMode = .byWordWrapping
        h3.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        h3.textColor = Color.grayPrimary.darker(by: 10)
        h3.backgroundColor = bkColor
        h3.text = "You have no events today"
        v.addSubview(h3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 ) { [weak self] in
            guard let self = self else { return }
            guard let org = self.org else { return }
            let events = WhisperCalendar.shared.getEvents(for: org)
            if events.count > 0 {
                if events.count > 1 {
                    h3.text = "You have \(events.count) upcoming events"
                } else {
                    h3.text = "You have 1 upcoming event"
                }
            }
        }
    }
    
}






