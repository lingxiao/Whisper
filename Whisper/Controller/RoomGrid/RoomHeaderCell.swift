//
//  RoomHeaderCell.swift
//  byte
//
//  Created by Xiao Ling on 12/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- protocol

protocol RoomHeaderCellDelegate {
    func handleTapRoomHeader( on club: Club?, from room: Room?, with user: User? ) -> Void
}


class RoomHeaderView : UIView {
    
    var delegate: HomeHeaderDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with club: Club? ){
        let f = self.frame
        let cell  = RoomHeaderCell()
        cell.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height)
        cell.selectionStyle = .none
        cell.config( with: club, room: nil )
        addSubview(cell)
    }
    
}

//MARK:- cell

class RoomHeaderCell: UITableViewCell {

    static let identifier = "RoomHeaderCell"
    var delegate : RoomHeaderCellDelegate?

    // view
    var container: UIView?
    var img: UIImageView?
    var h1: VerticalAlignLabel?
    var h2: VerticalAlignLabel?

    // data
    var club: Club?
    var room: Room?
    private var changing: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.h2?.removeFromSuperview()
        self.container?.removeFromSuperview()
    }
    
    func config( with club: Club?, room: Room?, showImage: Bool = true ){

        self.club = club
        self.room = room
        self.backgroundColor = Color.primary

        layout( showImage )
        
        //let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        //self.addGestureRecognizer(tap)

    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.handleTapRoomHeader(on: self.club, from: room, with: nil)
    }
    
    @objc func onTapMore(_ notification: NSNotification){
        delegate?.handleTapRoomHeader(on: self.club, from: room, with: nil)
    }

    
    //MARK:- view

    private func layout( _ showImage: Bool ){
        
        let f = self.frame
        let R = f.height - 20
        let r = f.height-40
        let dx = showImage ? R + 35 : 15
        let wd = f.width - dx - 15 - r - 5

        // container view
        let parent = UIView(frame:CGRect(x: 10, y: 0, width: f.width-20, height: f.height))
        parent.backgroundColor = Color.graySecondary
        addSubview(parent)
        parent.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: f.height/6)
        self.container = parent
        
        let pf = parent.frame
        
        // image view
        if showImage {
            let v = UIImageView(frame:CGRect(x:20, y:(f.height-R)/2, width: R, height: R))
            let _ = v.corner(with: R/8)
            v.backgroundColor = Color.grayTertiary
            ImageLoader.shared.injectImage( from: club?.fetchThumbURL(), to: v ){ succ in return }
            parent.addSubview(v)
            self.img = v
        }
        
        
        // name of club
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: wd, height: f.height/2)
        h1.textAlignment = .left
        h1.verticalAlignment = .bottom
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h1.textColor = Color.primary_dark
        h1.text = club?.get_H1() ?? ""

        parent.addSubview(h1)
        self.h1 = h1
        
        // num of people in room
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: f.height/2+5, width: wd, height: f.height/2-5)
        h2.textAlignment = .left
        h2.verticalAlignment = .top
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        h2.textColor = Color.primary_dark
        
        parent.addSubview(h2)
        self.h2 = h2

        var str = ""
        
        if GLOBAL_DEMO {
            let n = Int.random(in: 30..<100)
            str = "\(n) people are in the room"
        } else {
            if let n = room?.getAttending().count {
                let num = Double(n).formatPoints()
                str = n > 1 ? "\(num) people are in the room." : "1 person is live in this room."
            }
        }
        
        h2.text = str

        guard let club = self.club else { return }
        
        // determine if this club can be edited by me
        let b1  = club.type == .cohort && club.creatorID == UserAuthed.shared.uuid
        let b2  = club.type == .home && club.creatorID == UserAuthed.shared.uuid
           
        // cohorts have their own settings
        if b1 || b2 {
            let icon = TinderButton()
            icon.frame = CGRect(x:pf.width-r-5,y:(pf.height-r)/2, width:r, height:r)
            icon.changeImage(to: "vdots", alpha: 1.0, scale: 0.40, color: Color.grayPrimary.darker(by: 50))
            icon.backgroundColor = Color.graySecondary
            icon.addTarget(self, action: #selector(onTapMore), for: .touchUpInside)
            parent.addSubview(icon)
            icon.center.x = f.width - 20 - R/2
            let _ = self.tappable(with: #selector(handleTap))
        }
    }    
    
}
