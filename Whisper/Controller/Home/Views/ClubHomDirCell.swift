//
//  ClubHomDirCell.swift
//  byte
//
//  Created by Xiao Ling on 1/28/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

//MARK:- directory cell

private let bkColor = UIColor.white

enum ClubHomeDirCellType {
    case home
    case live
    case newItem
}

protocol ClubHomeDirCellDelegate {
    func onTapHomeClub( at club: Club? ) -> Void
    func onTapIcon( at club: Club? ) -> Void
    func onTap(user:User?) -> Void
}


class ClubHomeDirCell : UITableViewCell, UserRowCellProtocol {
   
    
    static let identifier = "ClubHomeDirCell"
    var delegate : ClubHomeDirCellDelegate?

    // view
    var img: UIImageView?
    var h1: VerticalAlignLabel?
    var h2: VerticalAlignLabel?
    var dot: UIImageView?
    var textLIVE: UITextView?
    var ho: UILabel?
    var icon: TinderButton?
    private var pvs: ProfileRowSmall?
    private var pvb: ProfileRowBig?
    var container: UIImageView?

    // data
    var club: Club?
    var org: OrgModel?
    var user: User?
    var pictures: [URL?] = []
    private var changing: Bool = false
    
    static func Height( type: ClubHomeDirCellType ) -> CGFloat {
        switch type{
        case .home:
            return 10 + 10 + 60 + 30 + 120 + 10
        case .live:
            return 10 + (AppFontSize.footerBold * 2 + 20) + 10 + 120 + 10
        case .newItem:
            return 10 + 10 + 60 + 20
        }
    }


    override func prepareForReuse() {

        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.h2?.removeFromSuperview()
        self.textLIVE?.removeFromSuperview()
        self.container?.removeFromSuperview()
        self.ho?.removeFromSuperview()
        self.icon?.removeFromSuperview()
        self.pvs?.stripDown()
        self.pvb?.stripDown()
        self.pvs?.removeFromSuperview()
        self.pvb?.removeFromSuperview()
        if let cv = self.container {
            for v in cv.subviews {
                v.removeFromSuperview()
            }
            cv.removeFromSuperview()
        }

    }

    func config( with club: Club?, at org: OrgModel?, type: ClubHomeDirCellType ){
        self.club = club
        self.org = org
        layout( club, type )
        let _ = self.tappable(with: #selector(onTap))
    }
    
    @objc func onTap(){
        delegate?.onTapHomeClub(at: self.club)
    }

    func layout( _ club: Club?, _ type: ClubHomeDirCellType ){

        self.container?.removeFromSuperview()
        
        // container view
        let f = self.frame
        let ht = f.height-20

        var R: CGFloat = 60
        var topHt: CGFloat = R
        var dx: CGFloat = 20
        var dy: CGFloat = 10

        switch type{
        case .live:
            R = AppFontSize.footer
            topHt = AppFontSize.footerBold * 2 + 20
            dx = R + 30
        default:
            R = 60
            topHt = R
            dx = R + 25
        }

        // parent container
        let parent = UIImageView(frame:CGRect(x: 10, y: dy, width: f.width-20, height: ht))
        parent.backgroundColor = bkColor
        
        var isLIVE : Bool = type == .live
        if let club = club {
            isLIVE = club.someoneIsLiveHere()
        }

        if isLIVE {
            parent.applyShadowWithCornerRadius(
                color: Color.graySecondary.darker(by: 5),
                opacity: 1.0,
                cornerRadius: 15,
                radius: 2,
                edge: AIEdge.Bottom_Right,
                shadowSpace: 2
            )
        } else {
            parent.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 15)
            parent.addBottomBorderWithColor(color:Color.graySecondary,width:4.0)
            parent.addRightBorderWithColor(color:Color.graySecondary,width:3.0)
        }
        
        addSubview(parent)
        self.container = parent

        // img
        switch type {
        case .live:
            // live dot
            let dot = UIImageView(frame: CGRect(x: 20, y: 10+(topHt-R)/2, width: R, height: R))
            let _ = dot.round()
            dot.backgroundColor = Color.redDark
            parent.addSubview(dot)
            self.dot = dot
        default:
            let v = UIImageView(frame:CGRect(x:10, y: dy, width: R, height: R))
            let _ = v.corner(with:R/8)
            v.backgroundColor = Color.primary
            
            if let url = club?.fetchThumbURL() {
                ImageLoader.shared.injectImage( from: url, to: v ){ succ in return }
            } else {
                var char : String = ""
                if let club = club {
                    char = String(club.get_H1().prefix(1))
                }
                let sz = R/3
                let ho = UILabel(frame: CGRect(x: (R-sz)/2, y: (R-sz)/2, width: sz, height: sz))
                ho.font = UIFont(name: FontName.bold, size: sz)
                ho.textAlignment = .center
                ho.textColor = Color.grayQuaternary.darker(by: 50)
                ho.text = char.uppercased()
                self.ho = ho
                v.addSubview(ho)
            }
            
            // mount
            parent.addSubview(v)
            self.img = v

        }

        // name
        let wd = parent.frame.width - R - 30 - 20 - 40
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: dy, width: wd, height: topHt/2)
        h1.textAlignment = .left
        h1.verticalAlignment = .bottom
        h1.font = UIFont(name: FontName.bold, size: type == .home ? AppFontSize.body2 : AppFontSize.footerBold)
        h1.textColor = Color.primary_dark
        h1.text = club?.get_H1() ?? ""
        parent.addSubview(h1)
        self.h1 = h1
        
        dy += topHt/2
        
        // num of people in room
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: dy, width: wd, height: topHt/2)
        h2.textAlignment = .left
        h2.verticalAlignment = type == .home ? .middle : .top
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        h2.textColor = Color.primary_dark
        parent.addSubview(h2)
        self.h2 = h2
        
        switch type {
        case .home:
            if let club = club {
                if club.someoneIsLiveHere() {
                    if GLOBAL_DEMO {
                        h2.text = "8 people are here"
                        h2.textColor = Color.redDark
                    } else {
                        let n = club.getNumAttendingInAllRooms()
                        let ppn = Double(n).formatPoints()
                        h2.text = n > 1 ? "\(ppn) people are here" : "1 person is here"
                        h2.textColor = Color.redDark
                    }
                } else {
                    h2.text = GLOBAL_DEMO
                        ? "36 channels, 452 members"
                        : (org?.get_H2() ?? "")
                }
            }
        case .live:
            if GLOBAL_DEMO {
                if let club = club {
                    if club.someoneIsLiveHere() {
                        h2.text = "8 people are in the room"
                    } else {
                        h2.text = "\(Int.random(in: 0..<34)) people are here"
                    }
                } else {
                    h2.text = "\(Int.random(in: 0..<34)) people are here"
                }
            } else {
                if let club = club {
                    if club.someoneIsLiveHere() {
                        let n = club.getNumAttendingInAllRooms()
                        let ppn = Double(n).formatPoints()
                        h2.text = n > 1 ? "\(ppn) people are here" : "1 person is here"
                    }
                }
            }
        case .newItem:
            if let club = club {
                if club.type == .ephemeral {
                    h2.text = "Ephemeral"
                } else {
                    h2.text = "Just created"
                }
            }
        }
        
        // room type icon
        let icon_R = type == .newItem ? topHt/3 : topHt/2
        var icon_str = ""
        var icolor = Color.white
        if let club = club {
            switch club.type {
            case .cohort:
                //icon_str = club.locked ? "hidden" : "hidden-false"
                //icolor   = club.locked ? Color.redDark : Color.greenDark
                icon_str = "pin-l"
                icolor = Color.grayPrimary
            case .home:
                icon_str = "fire"
                icolor = Color.redDark
            case .ephemeral:
                icon_str = "timer-2"
                icolor = Color.grayPrimary //purpleLite
            }
        }
        
        if icon_str != "" {
            let icon = TinderButton()
            icon.frame = CGRect(x: dx+wd+20, y: 15, width: icon_R , height: icon_R)
            icon.changeImage(to: icon_str, alpha: 1.0, scale: 3/4, color: icolor)
            icon.backgroundColor = parent.backgroundColor
            parent.addSubview(icon)
            self.icon = icon
        }

        dy += topHt
        
        
        // get users and layout heere
        var all_users:[User] = []
        switch type {
        case .home:
            if GLOBAL_DEMO {
                all_users = Array(UserList.shared.cached.values)
            } else {
                if let club = club {
                    if club.someoneIsLiveHere(){
                        all_users = club.getAttendingInRooms()
                    } else {
                        all_users = org?.getRelevantUsers() ?? []
                    }
                }
            }
        case .live:
            if GLOBAL_DEMO {
                all_users = Array(UserList.shared.cached.values)
            } else {
                all_users = club?.getAttendingInRooms() ?? []
            }
        default:
            break;
        }
        
        switch type {
        case .home:
            guard let club = club else { return }
            if club.someoneIsLiveHere(){
                let v = ProfileRowBig(frame:CGRect(x:0,y:dy,width:f.width,height:ht-dy))
                v.config(with:Array(all_users.prefix(4)) , in: club)
                addSubview(v)
                self.pvb = v
            } else {
                let v = ProfileRowSmall(frame:CGRect(x:0,y:dy,width:f.width,height:ht-dy))
                v.config(with:Array(all_users.prefix(9)) , in: club)
                v.delegate = self
                addSubview(v)
                self.pvs = v
            }
        case .live:
            let v = ProfileRowBig(frame:CGRect(x:0,y:dy,width:f.width,height:ht-dy))
            v.config(with:Array(all_users.prefix(4)) , in: club)
            addSubview(v)
            self.pvb = v
        default:
            break;
        }
    }
    
    
    func handleTap(on user: User?) {
        delegate?.onTap(user:user)
    }
    
    func handleBtn(on user: User?) {
        return
    }
    
}



//MARK:- profile row small


private class ProfileRowSmall : UIView, UserRowCellProtocol {

    var delegate:UserRowCellProtocol?
    var views: [UserRowCell] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

    func config( with users: [User], in club: Club?){

        let f = self.frame
        let width = (f.width-2*15-2*5)/3
        let height = (f.height - 10)/3

        var dx: CGFloat = 10
        for col in to3DArray(users){
            layoutColumn(users:col,dx:dx, dy:0, width: width, height: height)
            dx += width + 5
        }
    }
    
    func stripDown(){
        for v in views {
            v.removeFromSuperview()
        }
    }
    
    private func layoutColumn( users:[User], dx: CGFloat, dy: CGFloat, width: CGFloat, height: CGFloat ) {
        var dy = dy
        for user in users {
            let v = UserRowCell()
            v.frame = CGRect(x:dx,y:dy,width:width,height:height)
            v.config(with:user,button:false,bigFont:false)
            v.delegate = self
            v.backgroundColor = bkColor
            addSubview(v)
            dy += height + 5
            views.append(v)
        }
    }
    
    func handleTap(on user: User?) {
        delegate?.handleTap(on:user)
    }
    
    func handleBtn(on user: User?) {
        return
    }
    
    
}

private func to3DArray( _ reduced: [User] ) -> [[User]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/3) + 1
    
    while num > 0 {
        patternArray.append([0,0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    return res
}



//MARK:- profile row big

private class ProfileRowBig : UIView {

    var views: [ProfileCard] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with users: [User], in club: Club?){
        
        let f = self.frame
        var p_dx: CGFloat = 15
        let card_ht = f.height
        let dy = CGFloat(0)
        let card_wd = (f.width - 2*p_dx)/4

        for user in users {
            let v = ProfileCard(frame: CGRect(x: p_dx, y: dy, width: card_wd, height: card_ht))
            v.config(with: user, in: club, cardColor: Color.white, showCard: false)
            addSubview(v)
            p_dx += card_wd
        }

    }
    
    func stripDown(){
        for v in views {
            v.hideIndicator()
            v.removeFromSuperview()
        }
    }
    

    
}

//MARK:- profile view -

private class ProfileCard : UIView {
    
    var delegate: HomeFooterDelegate?
    
    // view
    var addBtn: TinderButton?
    var bell: TinderButton?
    private var img: UIImageView?

    // scroll state
    var prevHt: CGFloat = 0
    var lastOpen: Int = now()
    
    // live state
    var user: User?
    var club: Club?
    var speaking: Bool = false
    private var mute: UIImageView?

    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with user: User, in club: Club?, cardColor: UIColor, showCard:Bool ){
        
        self.user = user
        self.club = club
        
        let f = self.frame
        let ht = AppFontSize.footerLight+10
        let profile_R : CGFloat = min(f.height - ht - 5, f.width - 20)
        var dy : CGFloat = 0
        
        let v = UIView(frame: CGRect(x: 5, y: 0, width: f.width-10, height: f.height))
        let _ = v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 10)
        v.backgroundColor = cardColor
        addSubview(v)

        dy += showCard ? 10 : 5

        // profile image
        let p = UIImageView(frame: CGRect(x: 5, y: dy, width: profile_R, height: profile_R))
        let _ = p.round()
        let _ = p.border(width: 2.0, color: Color.redLite.cgColor)
        p.backgroundColor = Color.grayQuaternary
        v.addSubview(p)
        self.img = p
        
        dy += showCard ? profile_R + 2 : profile_R
        
        // name
        let label = UILabel()
        label.frame = CGRect( x:10, y: dy, width: profile_R-10, height: ht)
        label.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Color.grayPrimary
        v.addSubview(label)
        
        //speaking indicator
        if let club = club {

            if club.isLiveHere(user){
                label.text = "💬 \(user.get_H1())"
            } else {
                label.text = user.get_H1()
            }
        }
        
        
        // populate data
        if GLOBAL_DEMO {

            let (rand_name,_,rand_img) = getRandomUser()
            let pic = UIImage(named: rand_img)
            p.image = pic
            label.text = "💬 \(rand_name)"

        } else {

            var char: String = "A"
            char = String(user.get_H1().prefix(1))
                
            // fill in image
            DispatchQueue.main.async {
                if let url = user.fetchThumbURL() {
                    ImageLoader.shared.injectImage(from: url, to: p){ _ in return }
                } else {
                    let sz = AppFontSize.body2
                    let ho = UILabel(frame: CGRect(x: (profile_R-sz)/2, y:(profile_R-sz)/2, width: sz, height: sz))
                    ho.font = UIFont(name: FontName.bold, size: sz)
                    ho.textAlignment = .center
                    ho.textColor = Color.grayQuaternary.darker(by: 30)
                    ho.text = char.uppercased()
                    p.addSubview(ho)
                }
            }
            
        }
        
        // listen for mute
        listenForDidMute(on: self, for: #selector(didMute))
        listenForDidUnMute(on: self, for: #selector(didUnMute))
            
        // listen for speaking vs not
        listenForDidSpeaking(on:self, for: #selector(isSpeaking))
        listenForDidUnSpeaking(on:self, for: #selector(notSpeaking))
        
    }
    
    func hideIndicator(){
    }
    
    @objc func didMute(_ notification: NSNotification){
        if isForMe(notification){
            setMute(to: true)
        }
    }
    
    @objc func didUnMute(_ notification: NSNotification){
        if isForMe(notification){
            setMute(to: false)
        }
    }
    
    @objc func isSpeaking(_ notification: NSNotification){
        if isForMe(notification){
            setSpeaking(to: true)
        }
    }
    
    @objc func notSpeaking(_ notification: NSNotification){
        if isForMe(notification){
            setSpeaking(to: false)
        }
    }

    // @use: add mute
    func setMute( to muted: Bool ){
        /*if muted {
            if let mt = self.mute {
                bringSubviewToFront(mt)
                mt.alpha = 1.0
            } else {
                let f = self.frame
                let R = f.height - AppFontSize.footerLight-10
                let r = R/5
                let raw = UIImageView(image: UIImage(named: "mic-off"))
                let img = raw.colored( Color.primary_dark )
                img.frame = CGRect(x:R-3,y:R-8, width: r,  height: r)
                self.addSubview(img)
                self.mute = img
                self.bringSubviewToFront(img)
            }
        } else {
            self.mute?.alpha = 0.0
        }*/
    }
    
    // @use: when speakikng, show ring
    func setSpeaking( to yes : Bool ){
        if yes && !self.speaking {
            self.speaking = true
            let _ = img?.addBorder(width: 2.0, color: Color.redDark.cgColor )
        } else if !yes && self.speaking {
            self.speaking = false
            let _ = img?.addBorder(width: 2.0, color: Color.redLite.cgColor )
        }
    }
    
    
     private func isForMe(_ notification: NSNotification) -> Bool {
        guard let user = user else { return false }
        guard let club = club else { return false }
        guard let uid = decodePayloadForField(field: "userID", notification) else { return false }
        return club.isLiveHere(self.user) && user.uuid == uid
     }
    
}
