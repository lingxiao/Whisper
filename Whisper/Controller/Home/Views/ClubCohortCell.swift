//
//  ClubCohortCell.swift
//  byte
//
//  Created by Xiao Ling on 1/29/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit
import NVActivityIndicatorView


protocol ClubCohortCellDelegate {
    func onTapClub( at club: Club? ) -> Void
}


private let bkColor = UIColor.white


//MARK:- Cell


/*
 @Use: display user's screen
*/
class ClubCohortCell: UITableViewCell, ClubCohortCellDelegate {

    static var identifier: String = "ClubCohortCell"
    
    var parent: UIView?
    var delegate: ClubCohortCellDelegate?

    fileprivate var cells : [ClubCohortCellView] = []
    
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
    
    func onTapClub(at club: Club?) {
        delegate?.onTapClub(at: club)
    }

    static func Height() -> CGFloat {
        return ClubCohortCellView.Height()
    }
    
    func config( with clubs: [Club?] ){

        let f = self.frame
        let pv = UIView(frame: CGRect(x: 20, y: 5, width: f.width-20, height: f.height))
        pv.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 20)
        addSubview(pv)
        self.parent = pv

        //left
        var dx : CGFloat = 15
        let wd = (f.width - 2*dx - 10)/2
        let ht = f.height - 10
        
        for club in clubs {
            let v = ClubCohortCellView(frame: CGRect(x: dx, y: 10, width: wd, height: ht))
            v.config(with: club)
            addSubview(v)
            v.delegate = self
            self.cells.append(v)
            dx += wd + 10
        }
        
    }
        

}


//MARK:- one room view

private class ClubCohortCellView : UIView {
    
    var club : Club?
    var delegate: ClubCohortCellDelegate?
    
    var child: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func config( with club: Club? ){
        self.club = club
        let _ = self.tappable(with: #selector(onTap))
        if let club = club {
            layout( club )
        } else {
            layoutBlank()
        }
    }
    
    @objc func onTap(){
        delegate?.onTapClub(at: self.club)
    }

    private func layoutBlank(){

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
        h2.text = "Tap here to invite new members"
        h2.sizeToFit()
        v.addSubview(h2)
    }
    
    static func Height() -> CGFloat {
        var dy : CGFloat = 10
        let R : CGFloat = 60
        let ht = AppFontSize.footerBold
        dy += 20
        dy += ht + 5
        dy += R + 15
        dy += ht*1.5
        dy += 20
        return dy
    }
    
    // @Use: layout the view 
    private func layout( _ club: Club ){
        
        let f = self.frame
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height-20))
        v.backgroundColor = bkColor
        addSubview(v)
        self.child = v
        
        v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        v.addBottomBorderWithColor(color:Color.graySecondary,width:4.0)
        v.addRightBorderWithColor(color:Color.graySecondary,width:3.0)
        
        let dx: CGFloat = 20
        var dy: CGFloat = 10
        let R : CGFloat = 60
        let ht: CGFloat = AppFontSize.footerBold
        let wd = f.width-dx-40-ht
        
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: dy, width: wd, height: ht)
        h1.verticalAlignment = .middle
        h1.textAlignment = .left
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        h1.textColor = Color.grayPrimary
        h1.backgroundColor = bkColor
        v.addSubview(h1)
        
        if GLOBAL_DEMO {
            let dt = Int.random(in: 1..<43)
            h1.text = "Active \(dt)m ago"
        } else {
            h1.text = "Active \(computeAgo(from: club.timeStampLatest))"
        }
        
        // icon
        let icon_R = ht
        var icon_str = "fire"
        var icolor = Color.white
        switch club.type {
        case .cohort:
            //icon_str = club.locked ? "hidden" : "hidden-false"
            //icolor = club.locked ? Color.redDark : Color.greenDark
            icon_str = "pin-l"
            icolor = Color.grayPrimary
        case .home:
            icon_str = "fire"
            icolor = Color.redDark
        case .ephemeral:
            icon_str = "timer-2"
            icolor = Color.grayPrimary
        }
        let icon = TinderButton()
        icon.frame = CGRect(x: f.width-icon_R-10, y: dy, width: icon_R , height: icon_R)
        icon.changeImage(to: icon_str, alpha: 1.0, scale: 1.0, color: icolor)
        icon.backgroundColor = v.backgroundColor
        v.addSubview(icon)
        
        // make image
        dy += ht + 5
        mkImg(dx: dx, dy: dy, R: R, with: club)
        
        dy += R + 15
        
        //pictures
        var head: [URL?] = []
        var tail: [URL?] = []
        
        if GLOBAL_DEMO {
            for (_,user) in UserList.shared.cached {
                if let url = user.fetchThumbURL() {
                    head.append(url)
                } else {
                    tail.append(user.fetchThumbURL())
                }
            }
        } else {
            for url in club.getMembers().map({ $0.fetchThumbURL() }) {
                if let url = url {
                    head.append(url)
                } else {
                    tail.append(url)
                }
            }
        }
                
        head.append(contentsOf: tail)
        let vp = PictureRow()
        vp.frame = CGRect(x: dx, y: dy, width:f.width - dx - 30, height:ht*1.2)
        vp.config(with: head, gap: ht*1.2/3, numPics: 3)
        v.addSubview(vp)
    }
    
    
    private func mkImg( dx: CGFloat, dy: CGFloat, R: CGFloat, with club: Club){
        
        guard let child = child else { return }
        let f = child.frame

        let p = UIImageView(frame: CGRect(x: dx, y: dy, width: R, height: R))
        let _ = p.corner(with:R/8)
        p.backgroundColor = Color.blue1

        // creator
        let h2 = UITextView()
        h2.isUserInteractionEnabled = false
        h2.frame = CGRect( x:dx+R+2, y: dy, width: f.width-dx-5-R-10, height: R)
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = bkColor
        h2.text = club.get_H1()
        
        child.addSubview(h2)
        child.addSubview(p)
        
        DispatchQueue.main.async {
            if let url = club.fetchThumbURL() {
                ImageLoader.shared.injectImage(from: url, to: p){ _ in return }
            } else {
                var char : String = ""
                char = String(club.get_H1().prefix(1))
                let sz = R/3
                let ho = UILabel(frame: CGRect(x: (R-sz)/2, y: (R-sz)/2, width: sz, height: sz))
                ho.font = UIFont(name: FontName.bold, size: sz)
                ho.textAlignment = .center
                ho.textColor = Color.grayQuaternary.darker(by: 50)
                ho.text = char.uppercased()
                p.addSubview(ho)
            }
        }
    }

}






